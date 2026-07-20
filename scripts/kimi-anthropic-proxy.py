#!/usr/bin/env python3
"""
Kimi/Moonshot Anthropic-compatible proxy for opencode.

Why: opencode AI SDK + @ai-sdk/openai-compatible sends temperature:0 (which Moonshot
rejects) and reasoning consumes all output_tokens (leaving no room for content).
The Anthropic-compatible endpoint accepts temperature:1 and supports
thinking.budget_tokens to constrain reasoning budget. This proxy lets opencode
use the familiar OpenAI protocol while we apply Moonshot-specific defaults
server-side.

Streaming: Anthropic endpoint uses chunked transfer + Cloudflare buffering.
Reasoning models (kimi-k3) silently "think" for 10-60s before emitting text.
We use raw sockets with NO per-read timeout, TCP keep-alive, and periodic
SSE comments to keep opencode's connection alive.
"""
import json
import os
import socket
import ssl
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
import uuid
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

MOONSHOT_API_KEY = os.environ.get("MOONSHOT_API_KEY", "")
ANTHROPIC_BASE = os.environ.get("ANTHROPIC_BASE", "https://api.moonshot.ai/anthropic")
PORT = int(os.environ.get("KIMI_PROXY_PORT", "9876"))
REQUEST_TIMEOUT = int(os.environ.get("KIMI_PROXY_TIMEOUT", "600"))
KEEPALIVE_INTERVAL = float(os.environ.get("KIMI_PROXY_KEEPALIVE", "5"))


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
        if d.get("type") == "thinking_delta":
            return {"id": msg_id, "object": "chat.completion.chunk", "created": int(time.time()),
                    "model": model, "choices": [{"index": 0, "delta": {"reasoning_content": d.get("thinking", "")}, "finish_reason": None}]}
    if t == "message_delta":
        sr = evt.get("delta", {}).get("stop_reason")
        return {"id": msg_id, "object": "chat.completion.chunk", "created": int(time.time()),
                "model": model, "choices": [{"index": 0, "delta": {}, "finish_reason": sr}]}
    return None


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


class _KeepaliveSender:
    """Writes SSE comment lines periodically so the client knows we're alive."""

    def __init__(self, wfile):
        self.wfile = wfile
        self.last_write = time.time()
        self._closed = False

    def write(self, data):
        if self._closed:
            return
        try:
            self.wfile.write(data)
            self.wfile.flush()
            self.last_write = time.time()
        except (BrokenPipeError, ConnectionResetError, OSError):
            self._closed = True
            raise

    def alive(self):
        return not self._closed

    def maybe_heartbeat(self):
        if self._closed:
            return False
        if time.time() - self.last_write >= KEEPALIVE_INTERVAL:
            try:
                self.wfile.write(b": keep-alive\n\n")
                self.wfile.flush()
                self.last_write = time.time()
            except (BrokenPipeError, ConnectionResetError, OSError):
                self._closed = True
                return False
        return True


def post_anthropic_streaming(anth_body, ka):
    """Stream response from Moonshot Anthropic → OpenAI SSE.

    The Moonshot /anthropic endpoint ignores HTTP Transfer-Encoding: chunked hints
    unless the JSON body includes `stream: true`. Without it, the response is a
    single JSON object. Cloudflare buffers responses while the model thinks
    (10-60s silent gaps), so we keep a short per-read timeout on the socket and
    emit periodic SSE heartbeats to keep opencode's connection alive.
    """
    anth_body = dict(anth_body)
    anth_body["stream"] = True
    body_bytes = json.dumps(anth_body).encode()
    req = urllib.request.Request(
        ANTHROPIC_BASE + "/v1/messages",
        data=body_bytes,
        headers={"Content-Type": "application/json", "x-api-key": MOONSHOT_API_KEY,
                 "anthropic-version": "2023-06-01", "Accept": "text/event-stream"},
    )
    msg_id = f"chatcmpl-{uuid.uuid4().hex[:24]}"
    model = anth_body.get("model", "kimi-k3")
    pending = b""
    event_count = 0
    seen_done = False

    try:
        resp = urllib.request.urlopen(req, timeout=REQUEST_TIMEOUT)
    except Exception as e:
        sys.stderr.write(f"[kimi-proxy] connect error: {e}\n")
        try:
            ka.write(f"data: {json.dumps({'error': str(e)})}\n\n".encode())
            ka.write(b"data: [DONE]\n\n")
        except Exception:
            pass
        return

    try:
        # Read status line via .status
        status = resp.status
        sys.stderr.write(f"[kimi-proxy] upstream status: {status}\n")
        if status != 200:
            err = resp.read().decode(errors="replace")
            ka.write(f"data: {json.dumps({'error': err})}\n\n".encode())
            ka.write(b"data: [DONE]\n\n")
            return

        # Set a short socket timeout so we can send heartbeats during the
        # Cloudflare-buffered "thinking" gap (10-60s).
        sock = None
        try:
            if hasattr(resp, 'fp') and hasattr(resp.fp, 'raw') and hasattr(resp.fp.raw, '_sock'):
                sock = resp.fp.raw._sock
            elif hasattr(resp, 'fp') and hasattr(resp.fp, 'sock'):
                sock = resp.fp.sock
        except Exception:
            pass
        if sock is not None:
            try:
                sock.settimeout(2.0)
            except Exception:
                pass

        while ka.alive():
            ka.maybe_heartbeat()
            try:
                chunk = resp.read1(4096) if hasattr(resp, 'read1') else resp.read(4096)
            except (socket.timeout, TimeoutError):
                continue
            except Exception as e:
                sys.stderr.write(f"[kimi-proxy] read err: {type(e).__name__}: {e}\n")
                break
            if not chunk:
                break
            pending += chunk
            ka.maybe_heartbeat()
            while b"\n" in pending:
                line_bytes, _, pending = pending.partition(b"\n")
                line = line_bytes.decode(errors="replace").rstrip("\r")
                if not line:
                    continue
                if not line.startswith("data: "):
                    continue
                data = line[6:]
                if data == "[DONE]":
                    seen_done = True
                    break
                try:
                    evt = json.loads(data)
                except Exception:
                    continue
                out = anthropic_chunk_to_openai(evt, msg_id, model)
                if out is None:
                    continue
                event_count += 1
                try:
                    ka.write(f"data: {json.dumps(out, ensure_ascii=False)}\n\n".encode())
                except (BrokenPipeError, ConnectionResetError):
                    return
            if seen_done:
                break
    finally:
        try:
            resp.close()
        except Exception:
            pass
    sys.stderr.write(f"[kimi-proxy] stream done: events={event_count} seen_done={seen_done} pending={len(pending)}b\n")
    try:
        ka.write(b"data: [DONE]\n\n")
    except Exception:
        pass


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"
    server_version = "kimi-anthropic-proxy/2.1"

    def log_message(self, format, *args):
        sys.stderr.write("[kimi-proxy] " + (format % args) + "\n")

    def _send(self, status, body, content_type="application/json", chunked=False):
        if isinstance(body, (dict, list)):
            payload = json.dumps(body).encode()
        elif isinstance(body, str):
            payload = body.encode()
        else:
            payload = body
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        if chunked:
            self.send_header("Transfer-Encoding", "chunked")
        else:
            self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)
        self.wfile.flush()

    def do_GET(self):
        if self.path == "/v1/models":
            payload = json.dumps({"object": "list", "data": [
                {"id": "kimi-k3", "object": "model", "owned_by": "moonshot"},
                {"id": "kimi-k2.7-code", "object": "model", "owned_by": "moonshot"},
                {"id": "kimi-k2.7-code-highspeed", "object": "model", "owned_by": "moonshot"},
            ]}).encode()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(payload)))
            self.end_headers()
            self.wfile.write(payload)
            return
        if self.path == "/health":
            self.send_response(200)
            self.send_header("Content-Type", "text/plain")
            self.send_header("Content-Length", "2")
            self.end_headers()
            self.wfile.write(b"ok")
            return
        self.send_response(404)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", "21")
        self.end_headers()
        self.wfile.write(b'{"error":"not found"}')

    def do_POST(self):
        if not self.path.startswith("/v1/chat/completions"):
            self.send_response(404)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", "21")
            self.end_headers()
            self.wfile.write(b'{"error":"not found"}')
            return
        length = int(self.headers.get("Content-Length", 0))
        try:
            body = json.loads(self.rfile.read(length))
        except Exception as e:
            err = json.dumps({"error": f"bad json: {e}"}).encode()
            self.send_response(400)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(err)))
            self.end_headers()
            self.wfile.write(err)
            return

        anth_body = translate_openai_to_anthropic(body)
        model = anth_body["model"]
        stream = bool(body.get("stream", False))

        if not stream:
            try:
                req = urllib.request.Request(
                    ANTHROPIC_BASE + "/v1/messages",
                    data=json.dumps(anth_body).encode(),
                    headers={"Content-Type": "application/json", "x-api-key": MOONSHOT_API_KEY,
                             "anthropic-version": "2023-06-01"},
                )
                with urllib.request.urlopen(req, timeout=REQUEST_TIMEOUT) as resp:
                    data = json.loads(resp.read())
                    payload = json.dumps(anthropic_response_to_openai(data, model)).encode()
                    self.send_response(200)
                    self.send_header("Content-Type", "application/json")
                    self.send_header("Content-Length", str(len(payload)))
                    self.end_headers()
                    self.wfile.write(payload)
            except urllib.error.HTTPError as e:
                try:
                    err = e.read()
                except Exception:
                    err = str(e).encode()
                self.send_response(e.code)
                self.send_header("Content-Type", "application/json")
                self.send_header("Content-Length", str(len(err)))
                self.end_headers()
                self.wfile.write(err)
            except Exception as e:
                err = json.dumps({"error": str(e)}).encode()
                self.send_response(500)
                self.send_header("Content-Type", "application/json")
                self.send_header("Content-Length", str(len(err)))
                self.end_headers()
                self.wfile.write(err)
            return

        # Streaming
        ka = _KeepaliveSender(self.wfile)
        try:
            self.send_response(200)
            self.send_header("Content-Type", "text/event-stream; charset=utf-8")
            self.send_header("Cache-Control", "no-cache")
            self.send_header("X-Accel-Buffering", "no")
            self.send_header("Transfer-Encoding", "chunked")
            self.send_header("Connection", "close")
            self.end_headers()
            self.wfile.flush()
        except (BrokenPipeError, ConnectionResetError):
            return
        try:
            post_anthropic_streaming(anth_body, ka)
        except (BrokenPipeError, ConnectionResetError):
            sys.stderr.write("[kimi-proxy] client disconnected\n")
        except Exception as e:
            sys.stderr.write(f"[kimi-proxy] streaming error: {e}\n")
            try:
                ka.write(f"data: {json.dumps({'error': str(e)})}\n\n".encode())
                ka.write(b"data: [DONE]\n\n")
            except Exception:
                pass


class ThreadedServer(ThreadingHTTPServer):
    daemon_threads = True
    allow_reuse_address = True


def main():
    if not MOONSHOT_API_KEY:
        print("ERROR: MOONSHOT_API_KEY env var required", file=sys.stderr)
        sys.exit(1)
    server = ThreadedServer(("127.0.0.1", PORT), Handler)
    print(f"[kimi-proxy] Listening on http://127.0.0.1:{PORT} (threading, v2.1)", file=sys.stderr)
    print(f"[kimi-proxy] Forwarding to {ANTHROPIC_BASE}", file=sys.stderr)
    print(f"[kimi-proxy] Timeout={REQUEST_TIMEOUT}s, keepalive={KEEPALIVE_INTERVAL}s", file=sys.stderr)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()
