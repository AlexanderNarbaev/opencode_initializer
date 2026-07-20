#!/usr/bin/env python3
"""
Kimi/Moonshot proxy for opencode (v5.0 - reasoning-content stripper).

Why: opencode 1.18.3 has a bug where it hangs when streaming responses that
include the non-standard 'reasoning_content' field. Moonshot models always
return this field. This proxy translates OpenAI <-> Anthropic AND strips
reasoning_content from the response, sending only 'content' to opencode.

Use case: makes moonshotai/kimi-k3 work with your own Moonshot API key in
opencode TUI (instead of using opencode-go's default routing).
"""
import json
import os
import sys
import threading
import time
import uuid
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

import httpx

MOONSHOT_API_KEY = os.environ.get("MOONSHOT_API_KEY", "")
ANTHROPIC_BASE = os.environ.get("ANTHROPIC_BASE", "https://api.moonshot.ai/anthropic")
print(f"[kimi-proxy v5] key length: {len(MOONSHOT_API_KEY)}, starts with: {MOONSHOT_API_KEY[:8] if MOONSHOT_API_KEY else 'NONE'}", file=sys.stderr)
PORT = int(os.environ.get("KIMI_PROXY_PORT", "9876"))
REQUEST_TIMEOUT = int(os.environ.get("KIMI_PROXY_TIMEOUT", "120"))


def translate_openai_to_anthropic(body):
    model = body.get("model", "kimi-k3")
    max_tokens = int(body.get("max_tokens") or body.get("max_completion_tokens") or 16384)
    temperature = body.get("temperature", 1)

    msgs = []
    for m in body.get("messages", []):
        content = m.get("content", "")
        if isinstance(content, list):
            content = "".join(p.get("text", "") if isinstance(p, dict) else str(p) for p in content)
        msgs.append({"role": m.get("role"), "content": content or " "})

    anth = {
        "model": model,
        "max_tokens": max_tokens,
        "messages": msgs,
        "temperature": temperature,
    }

    thinking_budget = max(256, min(8192, max_tokens // 4))
    anth["thinking"] = {"type": "enabled", "budget_tokens": thinking_budget}

    sys_prompt = body.get("system")
    if sys_prompt:
        if isinstance(sys_prompt, list):
            sys_prompt = "".join(p.get("text", "") if isinstance(p, dict) else str(p) for p in sys_prompt)
        anth["system"] = sys_prompt

    tools = body.get("tools")
    if tools:
        anth_tools = []
        for t in tools:
            if t.get("type") == "function":
                anth_tools.append({
                    "name": t["function"]["name"],
                    "description": t["function"].get("description", ""),
                    "input_schema": t["function"].get("parameters", {"type": "object"}),
                })
        if anth_tools:
            anth["tools"] = anth_tools
    return anth


def strip_reasoning(d):
    """Remove reasoning_content from a delta object. OpenAI-compatible."""
    if isinstance(d, dict) and "reasoning_content" in d:
        d = dict(d)
        d.pop("reasoning_content", None)
    return d


def anthropic_chunk_to_openai(evt, msg_id, model):
    t = evt.get("type")
    if t == "message_start":
        return {"id": msg_id, "object": "chat.completion.chunk", "created": int(time.time()),
                "model": model, "choices": [{"index": 0, "delta": {"role": "assistant"}, "finish_reason": None}]}
    if t == "content_block_start":
        block = evt.get("content_block", {})
        if block.get("type") == "tool_use":
            return {"id": msg_id, "object": "chat.completion.chunk", "created": int(time.time()),
                    "model": model, "choices": [{"index": 0, "delta": {"tool_calls": [{
                        "index": 0, "id": block.get("id", f"call_{uuid.uuid4().hex[:8]}"),
                        "type": "function", "function": {"name": block.get("name", ""), "arguments": ""}
                    }]}, "finish_reason": None}]}
    if t == "content_block_delta":
        d = evt.get("delta", {})
        if d.get("type") == "text_delta":
            return {"id": msg_id, "object": "chat.completion.chunk", "created": int(time.time()),
                    "model": model, "choices": [{"index": 0, "delta": {"content": d.get("text", "")}, "finish_reason": None}]}
        if d.get("type") == "input_json_delta":
            return {"id": msg_id, "object": "chat.completion.chunk", "created": int(time.time()),
                    "model": model, "choices": [{"index": 0, "delta": {"tool_calls": [{
                        "index": 0, "function": {"arguments": d.get("partial_json", "")}
                    }]}, "finish_reason": None}]}
        # STRIP reasoning_delta — this is what breaks opencode
        if d.get("type") == "thinking_delta":
            return None  # completely skip reasoning chunks
    if t == "message_delta":
        sr = evt.get("delta", {}).get("stop_reason")
        return {"id": msg_id, "object": "chat.completion.chunk", "created": int(time.time()),
                "model": model, "choices": [{"index": 0, "delta": {}, "finish_reason": sr}]}
    return None


def anthropic_response_to_openai(resp, model):
    msg_id = resp.get("id", f"chatcmpl-{uuid.uuid4().hex[:24]}")
    text = ""
    # SKIP reasoning - only return text content
    tool_calls = []
    for b in resp.get("content", []):
        btype = b.get("type")
        if btype == "text":
            text += b.get("text", "")
        # SKIP thinking blocks
        elif btype == "tool_use":
            tool_calls.append({"id": b.get("id", f"call_{uuid.uuid4().hex[:8]}"), "type": "function",
                               "function": {"name": b.get("name", ""), "arguments": json.dumps(b.get("input", {}))}})
    sr = resp.get("stop_reason", "end_turn")
    finish = {"end_turn": "stop", "max_tokens": "length", "tool_use": "tool_calls"}.get(sr, "stop")
    msg = {"role": "assistant", "content": text}
    if tool_calls:
        msg["tool_calls"] = tool_calls
    usage = resp.get("usage", {})
    return {"id": msg_id, "object": "chat.completion", "created": int(time.time()), "model": model,
            "choices": [{"index": 0, "message": msg, "finish_reason": finish}],
            "usage": {"prompt_tokens": usage.get("input_tokens", 0),
                      "completion_tokens": usage.get("output_tokens", 0),
                      "total_tokens": usage.get("input_tokens", 0) + usage.get("output_tokens", 0)}}


SESSIONS = threading.local()


def get_client():
    c = getattr(SESSIONS, "c", None)
    if c is None:
        # timeout: total request timeout. read/write timeouts are None for SSE streaming
        timeout = httpx.Timeout(connect=10.0, read=None, write=10.0, pool=10.0)
        c = httpx.Client(timeout=timeout)
        SESSIONS.c = c
    return c


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"
    server_version = "kimi-anthropic-proxy/5.0"

    def log_message(self, format, *args):
        sys.stderr.write("[kimi-proxy] " + (format % args) + "\n")

    def _write_response(self, status, body, content_type="application/json"):
        if isinstance(body, (dict, list)):
            payload = json.dumps(body).encode()
        else:
            payload = body if isinstance(body, bytes) else str(body).encode()
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(payload)))
        self.send_header("Connection", "close")
        self.end_headers()
        self.wfile.write(payload)
        self.wfile.flush()

    def do_GET(self):
        if self.path == "/v1/models":
            self._write_response(200, {"object": "list", "data": [
                {"id": "kimi-k3", "object": "model", "owned_by": "moonshot"},
                {"id": "kimi-k2.7-code", "object": "model", "owned_by": "moonshot"},
                {"id": "kimi-k2.7-code-highspeed", "object": "model", "owned_by": "moonshot"},
            ]})
        elif self.path == "/health":
            self._write_response(200, "ok", "text/plain")
        else:
            self._write_response(404, {"error": "not found"})

    def do_POST(self):
        if not self.path.startswith("/v1/chat/completions"):
            self._write_response(404, {"error": "not found"})
            return
        length = int(self.headers.get("Content-Length", 0))
        try:
            body = json.loads(self.rfile.read(length))
        except Exception as e:
            self._write_response(400, {"error": f"bad json: {e}"})
            return

        anth_body = translate_openai_to_anthropic(body)
        model = anth_body["model"]
        stream = bool(body.get("stream", False))

        sess = get_client()
        start = time.time()
        sys.stderr.write(f"[kimi-proxy] key to upstream: {MOONSHOT_API_KEY[:10]}... (len={len(MOONSHOT_API_KEY)})\n")

        if not stream:
            try:
                client = get_client()
                r = client.post(ANTHROPIC_BASE + "/v1/messages",
                               json=anth_body,
                               headers={"x-api-key": MOONSHOT_API_KEY, "anthropic-version": "2023-06-01"})
                elapsed = time.time() - start
                if r.status_code != 200:
                    sys.stderr.write(f"[kimi-proxy] upstream {r.status_code} in {elapsed:.1f}s\n")
                    self._write_response(r.status_code, {"error": r.text[:500]})
                    return
                data = r.json()
                sys.stderr.write(f"[kimi-proxy] non-stream OK in {elapsed:.1f}s\n")
                self._write_response(200, anthropic_response_to_openai(data, model))
            except Exception as e:
                sys.stderr.write(f"[kimi-proxy] ERR: {type(e).__name__}: {e}\n")
                self._write_response(500, {"error": str(e)[:200]})
            return

        # Streaming — chunked transfer encoding + strip reasoning
        try:
            self.send_response(200)
            self.send_header("Content-Type", "text/event-stream; charset=utf-8")
            self.send_header("Cache-Control", "no-cache")
            self.send_header("X-Accel-Buffering", "no")
            self.send_header("Transfer-Encoding", "chunked")
            self.send_header("Connection", "close")
            self.end_headers()
        except (BrokenPipeError, ConnectionResetError):
            return

        def write_chunk(data):
            if isinstance(data, str):
                data = data.encode("utf-8")
            try:
                self.wfile.write(f"{len(data):x}\r\n".encode())
                self.wfile.write(data)
                self.wfile.write(b"\r\n")
                self.wfile.flush()
                return True
            except (BrokenPipeError, ConnectionResetError, OSError):
                return False

        msg_id = f"chatcmpl-{uuid.uuid4().hex[:24]}"
        last_write = time.time()
        pending = b""
        event_count = 0
        client_alive = True
        try:
            client = get_client()
            with client.stream("POST", ANTHROPIC_BASE + "/v1/messages",
                               json=anth_body,
                               headers={"x-api-key": MOONSHOT_API_KEY, "anthropic-version": "2023-06-01", "Accept": "text/event-stream"},
                               timeout=REQUEST_TIMEOUT) as r:
                if r.status_code != 200:
                    err = r.read().decode(errors="replace")
                    if write_chunk(f"data: {json.dumps({'error': err})}\n\n".encode()):
                        write_chunk(b"data: [DONE]\n\n")
                    return

                for raw_chunk in r.iter_bytes(chunk_size=4096):
                    if not raw_chunk:
                        break
                    if time.time() - last_write >= 5:
                        if not write_chunk(b": keep-alive\n\n"):
                            client_alive = False
                            break
                        last_write = time.time()

                    pending += raw_chunk
                    while b"\n" in pending:
                        line_bytes, _, pending = pending.partition(b"\n")
                        line = line_bytes.decode(errors="replace").rstrip("\r")
                        if not line:
                            continue
                        if not line.startswith("data: "):
                            continue
                        data = line[6:]
                        if data == "[DONE]":
                            break
                        try:
                            evt = json.loads(data)
                        except Exception:
                            continue
                        out = anthropic_chunk_to_openai(evt, msg_id, model)
                        if out is None:
                            continue  # reasoning chunks dropped here
                        event_count += 1
                        chunk_data = f"data: {json.dumps(out, ensure_ascii=False)}\n\n".encode()
                        if not write_chunk(chunk_data):
                            client_alive = False
                            break
                        last_write = time.time()
                    if not client_alive:
                        break
        except Exception as e:
            sys.stderr.write(f"[kimi-proxy] stream err: {type(e).__name__}: {e}\n")

        try:
            write_chunk(b"data: [DONE]\n\n")
            self.wfile.write(b"0\r\n\r\n")
            self.wfile.flush()
        except Exception:
            pass
        sys.stderr.write(f"[kimi-proxy] stream end: events={event_count} (reasoning stripped) client_alive={client_alive}\n")


class ThreadedServer(ThreadingHTTPServer):
    daemon_threads = True
    allow_reuse_address = True


def main():
    if not MOONSHOT_API_KEY:
        print("ERROR: MOONSHOT_API_KEY env var required", file=sys.stderr)
        sys.exit(1)
    server = ThreadedServer(("127.0.0.1", PORT), Handler)
    print(f"[kimi-proxy v5] Listening on http://127.0.0.1:{PORT} (strip reasoning_content)", file=sys.stderr)
    print(f"[kimi-proxy v5] Forwarding to {ANTHROPIC_BASE}", file=sys.stderr)
    print(f"[kimi-proxy v5] Timeout={REQUEST_TIMEOUT}s", file=sys.stderr)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()
