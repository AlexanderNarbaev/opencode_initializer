#!/usr/bin/env python3
"""
Kimi/Moonshot Anthropic-compatible proxy for opencode (v4.0 - NON-streaming only).

Why non-streaming: opencode's ai-sdk has buffering issues with our streaming.
Non-streaming is slower but bulletproof. The reasoning model still returns
in 3-15 seconds for simple prompts.

Maps OpenAI /v1/chat/completions (with stream:true) → Anthropic /v1/messages
and returns the full response as a single OpenAI chunk.
"""
import json
import os
import sys
import threading
import time
import uuid
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

import requests
from requests.adapters import HTTPAdapter

MOONSHOT_API_KEY = os.environ.get("MOONSHOT_API_KEY", "")
ANTHROPIC_BASE = os.environ.get("ANTHROPIC_BASE", "https://api.moonshot.ai/anthropic")
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

    # Critical: constrain thinking budget so model leaves tokens for content
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


def anthropic_response_to_openai(resp, model):
    msg_id = resp.get("id", f"chatcmpl-{uuid.uuid4().hex[:24]}")
    text = ""
    reasoning = ""
    tool_calls = []
    for b in resp.get("content", []):
        btype = b.get("type")
        if btype == "text":
            text += b.get("text", "")
        elif btype == "thinking":
            reasoning += b.get("thinking", "")
        elif btype == "tool_use":
            tool_calls.append({"id": b.get("id", f"call_{uuid.uuid4().hex[:8]}"), "type": "function",
                               "function": {"name": b.get("name", ""), "arguments": json.dumps(b.get("input", {}))}})
    sr = resp.get("stop_reason", "end_turn")
    finish = {"end_turn": "stop", "max_tokens": "length", "tool_use": "tool_calls"}.get(sr, "stop")
    msg = {"role": "assistant", "content": text}
    if reasoning:
        msg["reasoning_content"] = reasoning
    if tool_calls:
        msg["tool_calls"] = tool_calls
    usage = resp.get("usage", {})
    return {"id": msg_id, "object": "chat.completion", "created": int(time.time()), "model": model,
            "choices": [{"index": 0, "message": msg, "finish_reason": finish}],
            "usage": {"prompt_tokens": usage.get("input_tokens", 0),
                      "completion_tokens": usage.get("output_tokens", 0),
                      "total_tokens": usage.get("input_tokens", 0) + usage.get("output_tokens", 0)}}


# Per-thread session to avoid sharing connections
SESSIONS = threading.local()


def get_session():
    s = getattr(SESSIONS, "s", None)
    if s is None:
        s = requests.Session()
        # Use a custom adapter that doesn't pool connections (per-request fresh)
        s.mount("https://", HTTPAdapter(pool_connections=1, pool_maxsize=1))
        SESSIONS.s = s
    return s


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"
    server_version = "kimi-anthropic-proxy/4.0"

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

        # We accept stream=true but ALWAYS do non-streaming internally.
        # opencode will see a single chunk and render it.
        # This is the most reliable path.
        stream = body.get("stream", False)

        anth_body = translate_openai_to_anthropic(body)
        model = anth_body["model"]

        sess = get_session()
        start = time.time()
        try:
            r = sess.post(ANTHROPIC_BASE + "/v1/messages",
                           json=anth_body,
                           headers={"x-api-key": MOONSHOT_API_KEY, "anthropic-version": "2023-06-01"},
                           timeout=REQUEST_TIMEOUT)
            elapsed = time.time() - start

            if r.status_code != 200:
                sys.stderr.write(f"[kimi-proxy] upstream {r.status_code} in {elapsed:.1f}s\n")
                self._write_response(r.status_code, {"error": r.text[:500]})
                return

            data = r.json()
            result = anthropic_response_to_openai(data, model)

            # If opencode requested streaming, wrap the single response in a stream format
            # that has one initial chunk + [DONE]
            if stream:
                # Send as HTTP/1.1 chunked transfer-encoded SSE stream
                # (AI SDK / fetch implementations require Transfer-Encoding for streaming)
                self.protocol_version = "HTTP/1.1"
                self.send_response(200)
                self.send_header("Content-Type", "text/event-stream; charset=utf-8")
                self.send_header("Cache-Control", "no-cache")
                self.send_header("Transfer-Encoding", "chunked")
                self.send_header("Connection", "close")
                self.end_headers()

                def write_chunk(data):
                    """Write one HTTP/1.1 chunked encoding chunk."""
                    if isinstance(data, str):
                        data = data.encode("utf-8")
                    self.wfile.write(f"{len(data):x}\r\n".encode())
                    self.wfile.write(data)
                    self.wfile.write(b"\r\n")
                    self.wfile.flush()

                # First chunk: role
                first = {"id": result["id"], "object": "chat.completion.chunk",
                         "created": result["created"], "model": result["model"],
                         "choices": [{"index": 0, "delta": {"role": "assistant"}, "finish_reason": None}]}
                write_chunk(f"data: {json.dumps(first, ensure_ascii=False)}\n\n")
                # Second chunk: content + finish_reason
                chunk = {"id": result["id"], "object": "chat.completion.chunk",
                         "created": result["created"], "model": result["model"],
                         "choices": [{"index": 0, "delta": {
                             "content": result["choices"][0]["message"]["content"],
                             "reasoning_content": result["choices"][0]["message"].get("reasoning_content", "")
                         }, "finish_reason": result["choices"][0]["finish_reason"]}]}
                write_chunk(f"data: {json.dumps(chunk, ensure_ascii=False)}\n\n")
                write_chunk("data: [DONE]\n\n")
                # Final empty chunk to signal end of stream
                self.wfile.write(b"0\r\n\r\n")
                self.wfile.flush()
                sys.stderr.write(f"[kimi-proxy] stream OK in {elapsed:.1f}s (chunked)\n")
            else:
                sys.stderr.write(f"[kimi-proxy] OK in {elapsed:.1f}s\n")
                self._write_response(200, result)
        except requests.exceptions.Timeout as e:
            sys.stderr.write(f"[kimi-proxy] TIMEOUT after {time.time()-start:.1f}s: {e}\n")
            self._write_response(504, {"error": "upstream timeout", "details": str(e)[:200]})
        except Exception as e:
            sys.stderr.write(f"[kimi-proxy] ERR: {type(e).__name__}: {e}\n")
            self._write_response(500, {"error": str(e)[:200]})


class ThreadedServer(ThreadingHTTPServer):
    daemon_threads = True
    allow_reuse_address = True


def main():
    if not MOONSHOT_API_KEY:
        print("ERROR: MOONSHOT_API_KEY env var required", file=sys.stderr)
        sys.exit(1)
    server = ThreadedServer(("127.0.0.1", PORT), Handler)
    print(f"[kimi-proxy] Listening on http://127.0.0.1:{PORT} (v4.0 NON-streaming-to-Anthropic)", file=sys.stderr)
    print(f"[kimi-proxy] Forwarding to {ANTHROPIC_BASE}", file=sys.stderr)
    print(f"[kimi-proxy] Timeout={REQUEST_TIMEOUT}s", file=sys.stderr)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()
