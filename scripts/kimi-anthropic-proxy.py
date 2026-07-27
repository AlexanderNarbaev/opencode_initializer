#!/usr/bin/env python3
"""
Kimi/Moonshot proxy v14.2 — dynamic payload compression to fit 20KB limit.

 CRITICAL: opencode v1.18.5 @ai-sdk/openai-compatible expects SSE format:
     data: {json}\n\n

 v14.2 strips tool descriptions, deduplicates tools, and truncates message
 history to keep total payload under Moonshot API's ~20KB request limit.
"""
import json
import os
import socket
import sys
import time
import uuid
from http.server import BaseHTTPRequestHandler, HTTPServer

import requests


def _force_ipv4():
    """Monkey-patch urllib3 to force IPv4 DNS resolution. Idempotent."""
    from urllib3.util import connection
    if getattr(connection, "_opencode_kimi_ipv4_patched", False):
        return
    orig_create = connection.create_connection

    def patched(address, timeout=None, *a, **kw):
        host = address[0]
        port = address[1]
        infos = socket.getaddrinfo(host, port, socket.AF_INET, socket.SOCK_STREAM)
        if not infos:
            raise socket.gaierror(f"no IPv4 for {host}")
        af, socktype, proto, canonname, sa = infos[0]
        return orig_create((sa[0], port), timeout=timeout, *a, **kw)

    connection.create_connection = patched
    connection._opencode_kimi_ipv4_patched = True


KEY = os.environ.get("MOONSHOT_API_KEY", "")
BASE = os.environ.get("KIMI_PROXY_UPSTREAM", "https://api.moonshot.ai/v1")
PORT = int(os.environ.get("KIMI_PROXY_PORT", "9876"))
TIMEOUT = int(os.environ.get("KIMI_PROXY_TIMEOUT", "600"))
CONNECT_TIMEOUT = int(os.environ.get("KIMI_PROXY_CONNECT_TIMEOUT", str(TIMEOUT)))
UPSTREAM_MAX_TOKENS_CAP = int(os.environ.get("KIMI_PROXY_MAX_TOKENS", "8192"))
UPSTREAM_MIN_TOKENS = int(os.environ.get("KIMI_PROXY_MIN_TOKENS", "4096"))
MAX_BODY_KB = int(os.environ.get("KIMI_PROXY_MAX_BODY_KB", "20"))
MAX_MSGS = int(os.environ.get("KIMI_PROXY_MAX_MSGS", "15"))
MAX_TOOL_DESC = int(os.environ.get("KIMI_PROXY_MAX_TOOL_DESC", "80"))
MAX_TOOLS = int(os.environ.get("KIMI_PROXY_MAX_TOOLS", "10"))
MAX_MSG_CONTENT = int(os.environ.get("KIMI_PROXY_MAX_MSG_CONTENT", "400"))
STRIP_TOOL_PARAMS = os.environ.get("KIMI_PROXY_STRIP_TOOL_PARAMS", "0") == "1"
STICKY_TOOLS = os.environ.get("KIMI_PROXY_STICKY_TOOLS",
    "bash,read,write,edit,grep,glob,task,fetch_fetch,webfetch").split(",")

def optimize_request(body):
    tools = body.get("tools", [])
    msgs = body.get("messages", [])
    orig_tools = len(tools)
    orig_msgs = len(msgs)

    # Deduplicate tools, strip descriptions, prioritize sticky tools
    seen_names = set()
    sticky = []
    rest = []
    for t in tools:
        fn = t.get("function", {})
        name = fn.get("name", "")
        if name in seen_names:
            continue
        seen_names.add(name)
        fn = dict(fn)
        if MAX_TOOL_DESC >= 0 and len(fn.get("description", "")) > MAX_TOOL_DESC:
            fn["description"] = fn.get("description", "")[:MAX_TOOL_DESC]
        if STRIP_TOOL_PARAMS:
            fn["parameters"] = {"type": "object", "properties": {}, "required": []}
        t = dict(t)
        t["function"] = fn
        if name in STICKY_TOOLS:
            sticky.append(t)
        else:
            rest.append(t)
    new_tools = sticky + rest
    if len(new_tools) > MAX_TOOLS:
        new_tools = new_tools[:MAX_TOOLS]
    body["tools"] = new_tools

    # Trim message history
    if len(msgs) > MAX_MSGS:
        sys_msg = None
        tail = []
        for m in msgs:
            if m.get("role") == "system":
                sys_msg = m
            else:
                tail.append(m)
        kept = tail[-MAX_MSGS:]
        body["messages"] = [sys_msg] + kept if sys_msg else kept

    # Trim long message content
    for m in body["messages"]:
        content = m.get("content", "")
        if isinstance(content, str) and len(content) > MAX_MSG_CONTENT:
            m["content"] = content[:MAX_MSG_CONTENT] + "..."

    # Dynamic: if still over MAX_BODY_KB, progressively trim harder
    max_bytes = MAX_BODY_KB * 1024
    current = len(json.dumps(body))
    if current <= max_bytes:
        return orig_tools, orig_msgs

    # Round 1: reduce tools to 5
    body["tools"] = body["tools"][:5]
    current = len(json.dumps(body))
    if current <= max_bytes:
        return orig_tools, orig_msgs

    # Round 2: strip tool params
    for t in body["tools"]:
        t["function"]["parameters"] = {"type": "object", "properties": {}, "required": []}
    current = len(json.dumps(body))
    if current <= max_bytes:
        return orig_tools, orig_msgs

    # Round 3: reduce messages to 10
    msgs = body["messages"]
    sys_msg = [m for m in msgs if m.get("role") == "system"]
    other = [m for m in msgs if m.get("role") != "system"]
    body["messages"] = sys_msg + other[-10:]
    current = len(json.dumps(body))
    if current <= max_bytes:
        return orig_tools, orig_msgs

    # Round 4: truncate content to 200 chars
    for m in body["messages"]:
        content = m.get("content", "")
        if isinstance(content, str) and len(content) > 200:
            m["content"] = content[:200] + "..."
    current = len(json.dumps(body))
    if current <= max_bytes:
        return orig_tools, orig_msgs

    # Round 5: reduce to 3 tools, 5 messages, 100 chars
    body["tools"] = body["tools"][:3]
    msgs = body["messages"]
    sys_msg = [m for m in msgs if m.get("role") == "system"]
    other = [m for m in msgs if m.get("role") != "system"]
    body["messages"] = sys_msg + other[-5:]
    for m in body["messages"]:
        content = m.get("content", "")
        if isinstance(content, str) and len(content) > 100:
            m["content"] = content[:100] + "..."
    return orig_tools, orig_msgs

_force_ipv4()
print(f"[kimi-proxy v14.2] key_len={len(KEY)} base={BASE} port={PORT} "
      f"tokens={UPSTREAM_MIN_TOKENS}-{UPSTREAM_MAX_TOKENS_CAP} "
      f"(IPv4-only, SSE-format, tools+system passthrough)", file=sys.stderr)


def strip_reasoning_content(obj):
    if isinstance(obj, dict):
        obj.pop("reasoning_content", None)
        for v in obj.values():
            strip_reasoning_content(v)
    elif isinstance(obj, list):
        for item in obj:
            strip_reasoning_content(item)


class H(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, fmt, *args):
        sys.stderr.write("[v14.2] " + (fmt % args) + "\n")

    def _write(self, status, body, content_type="application/json"):
        if isinstance(body, (dict, list)):
            payload = json.dumps(body, ensure_ascii=False).encode("utf-8")
        elif isinstance(body, bytes):
            payload = body
        else:
            payload = str(body).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(payload)))
        self.send_header("Connection", "close")
        self.end_headers()
        self.wfile.write(payload)
        self.wfile.flush()

    def do_GET(self):
        if self.path == "/v1/models" or self.path == "/v1/models/":
            self._write(200, {"object": "list", "data": [
                {"id": "kimi-k3", "object": "model", "owned_by": "moonshot"},
                {"id": "kimi-k2.7-code", "object": "model", "owned_by": "moonshot"},
                {"id": "kimi-k2.7-code-highspeed", "object": "model", "owned_by": "moonshot"},
            ]})
        elif self.path == "/health":
            self._write(200, "ok", "text/plain")
        else:
            self._write(404, {"error": "not found"})

    def _sse_data(self, obj):
        """Write one SSE data: line."""
        d = json.dumps(obj, ensure_ascii=False)
        self.wfile.write(f"data: {d}\n\n".encode())
        self.wfile.flush()

    def do_POST(self):
        if not self.path.startswith("/v1/chat/completions"):
            self._write(404, {"error": "not found"})
            return
        cl = int(self.headers.get("Content-Length", 0))
        try:
            body = json.loads(self.rfile.read(cl)) if cl > 0 else {}
        except Exception as e:
            self._write(400, {"error": f"bad json: {e}"})
            return

        model = body.get("model", "kimi-k3")
        client_stream = body.get("stream", False)

        # Optimize request for Moonshot's ~20KB upstream limit
        orig_tools, orig_msgs = optimize_request(body)
        upstream_body = dict(body)
        upstream_body["stream"] = False
        client_max = upstream_body.get("max_tokens", 0)
        if client_max < UPSTREAM_MIN_TOKENS:
            upstream_body["max_tokens"] = UPSTREAM_MIN_TOKENS
        elif client_max > UPSTREAM_MAX_TOKENS_CAP:
            upstream_body["max_tokens"] = UPSTREAM_MAX_TOKENS_CAP
        upstream_body["temperature"] = 1

        t0 = time.time()
        payload_json = json.dumps(upstream_body)
        sys.stderr.write(f"[v14.2] request model={model} stream={client_stream} "
                         f"max_tokens={upstream_body.get('max_tokens')} "
                         f"tools={orig_tools}>{len(body.get('tools',[]))} "
                         f"msgs={orig_msgs}>{len(upstream_body.get('messages',[]))} "
                         f"payload={len(payload_json)}B\n")

        sse_started = False
        if client_stream:
            try:
                self.send_response(200)
                self.send_header("Content-Type", "text/event-stream; charset=utf-8")
                self.send_header("Cache-Control", "no-cache")
                self.send_header("X-Accel-Buffering", "no")
                self.send_header("Connection", "close")
                self.end_headers()
                ts0 = int(time.time())
                self._sse_data({
                    "id": "chatcmpl-keepalive",
                    "object": "chat.completion.chunk",
                    "created": ts0,
                    "model": model,
                    "choices": [{"index": 0, "delta": {"role": "assistant", "content": ""}, "finish_reason": None}],
                })
                sse_started = True
                sys.stderr.write(f"[v14.2] SSE headers + keepalive sent in {time.time()-t0:.2f}s\n")
            except (BrokenPipeError, ConnectionResetError, OSError) as e:
                sys.stderr.write(f"[v14.2] client closed before headers: {e}\n")
                return

        try:
            sys.stderr.write(f"[v14.2] upstream POST {BASE}/chat/completions timeout={TIMEOUT}s\n")
            r = requests.post(
                f"{BASE}/chat/completions",
                data=payload_json,
                headers={"Authorization": f"Bearer {KEY}", "Content-Type": "application/json"},
                timeout=TIMEOUT,
            )
        except Exception as e:
            err_obj = {"message": f"upstream: {e}", "type": "proxy_error", "code": "connection_error"}
            if sse_started:
                self._sse_data({"error": err_obj})
                self.wfile.write(b"data: [DONE]\n\n")
                self.wfile.flush()
            else:
                self._write(502, {"error": err_obj})
            return

        dt = time.time() - t0
        sys.stderr.write(f"[v14.2] upstream {r.status_code} in {dt:.1f}s body={len(r.text)}B\n")
        if r.status_code != 200:
            sys.stderr.write(f"[v14.2] upstream ERROR body: {r.text[:800]}\n")
            err_obj = {"message": r.text[:500], "type": "upstream_error", "code": str(r.status_code)}
            if sse_started:
                self._sse_data({"error": err_obj})
                self.wfile.write(b"data: [DONE]\n\n")
                self.wfile.flush()
            else:
                self._write(r.status_code, {"error": err_obj})
            return

        try:
            data = r.json()
        except Exception as e:
            sys.stderr.write(f"[v14.2] JSON parse error: {e}\n")
            err_obj = {"message": f"upstream not json: {e}", "type": "parse_error", "code": "invalid_response"}
            if sse_started:
                self._sse_data({"error": err_obj})
                self.wfile.write(b"data: [DONE]\n\n")
                self.wfile.flush()
            else:
                self._write(500, {"error": err_obj})
            return

        msg_raw = data.get("choices", [{}])[0].get("message", {})
        raw_content = msg_raw.get("content", "")
        raw_reasoning = msg_raw.get("reasoning_content", "")
        sys.stderr.write(f"[v14.2] before_strip content={len(raw_content)}B reasoning={len(raw_reasoning)}B\n")
        if raw_content:
            sys.stderr.write(f"[v14.2] content_preview={repr(raw_content[:80])}\n")

        strip_reasoning_content(data)

        if not client_stream:
            self._write(200, data)
            return

        msg = data.get("choices", [{}])[0].get("message", {})
        content = msg.get("content", "")
        finish = data.get("choices", [{}])[0].get("finish_reason", "stop")
        uid = data.get("id", f"chatcmpl-{uuid.uuid4().hex[:24]}")
        ts = int(time.time())

        self._sse_data({
            "id": uid, "object": "chat.completion.chunk", "created": ts,
            "model": model,
            "choices": [{"index": 0, "delta": {"content": content}, "finish_reason": finish}],
        })

        tool_calls = msg.get("tool_calls")
        if tool_calls:
            self._sse_data({
                "id": uid, "object": "chat.completion.chunk", "created": ts,
                "model": model,
                "choices": [{"index": 0, "delta": {"tool_calls": tool_calls}, "finish_reason": None}],
            })

        self.wfile.write(b"data: [DONE]\n\n")
        self.wfile.flush()
        sys.stderr.write(f"[v14.2] stream done {time.time()-t0:.1f}s content={len(content)}B\n")


class ThreadedServer(HTTPServer):
    allow_reuse_address = True
    request_queue_size = 1


if __name__ == "__main__":
    if not KEY:
        print("ERROR: MOONSHOT_API_KEY env var required", file=sys.stderr)
        sys.exit(1)
    print(f"[v14.2] listening http://127.0.0.1:{PORT} -> {BASE}", file=sys.stderr)
    ThreadedServer(("127.0.0.1", PORT), H).serve_forever()
