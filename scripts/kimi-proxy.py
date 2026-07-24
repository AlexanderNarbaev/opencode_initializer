#!/usr/bin/env python3
"""Kimi proxy v9 - non-streaming upstream, but returns SSE-format response to client."""
import json, os, sys, time, uuid
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import requests

KEY = os.environ.get("MOONSHOT_API_KEY", "")
PORT = int(os.environ.get("KIMI_PROXY_PORT", "9877"))


class H(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, fmt, *args):
        sys.stderr.write("[v9] " + (fmt % args) + "\n")

    def do_GET(self):
        if self.path == "/v1/models":
            d = json.dumps({"object": "list", "data": [
                {"id": "kimi-k3", "object": "model"},
                {"id": "kimi-k2.7-code", "object": "model"},
                {"id": "kimi-k2.7-code-highspeed", "object": "model"},
            ]}).encode()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(d)))
            self.end_headers()
            self.wfile.write(d)
        elif self.path == "/health":
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b"ok")
        else:
            self.send_response(404)
            self.end_headers()

    def do_POST(self):
        if not self.path.startswith("/v1/chat/completions"):
            self.send_response(404)
            self.end_headers()
            return
        cl = int(self.headers.get("Content-Length", 0))
        body = json.loads(self.rfile.read(cl)) if cl > 0 else {}
        model = body.get("model", "kimi-k3")
        client_stream = body.get("stream", False)
        t0 = time.time()
        sys.stderr.write(f"[v9] POST {model} client_stream={client_stream}\n")
        try:
            r = requests.post(
                "https://api.moonshot.ai/v1/chat/completions",
                json={"model": model, "messages": body.get("messages", []), "max_tokens": 4096, "temperature": 1.0},
                headers={"Authorization": f"Bearer {KEY}", "Content-Type": "application/json"},
                timeout=60,
            )
            dt = time.time() - t0
            sys.stderr.write(f"[v9] upstream {r.status_code} in {dt:.1f}s\n")
            if r.status_code != 200:
                d = json.dumps({"error": r.text[:500]}).encode()
                self.send_response(r.status_code)
                self.send_header("Content-Type", "application/json")
                self.send_header("Content-Length", str(len(d)))
                self.end_headers()
                self.wfile.write(d)
                return
            d = r.json()
        except Exception as e:
            sys.stderr.write(f"[v9] ERR: {e}\n")
            d = json.dumps({"error": str(e)}).encode()
            self.send_response(500)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(d)))
            self.end_headers()
            self.wfile.write(d)
            return

        msg = d["choices"][0]["message"]
        uid = d.get("id", "chatcmpl-" + uuid.uuid4().hex[:24])
        finish = d["choices"][0].get("finish_reason", "stop")
        ts = int(time.time())

        if not client_stream:
            # Non-streaming client: return JSON
            resp = {
                "id": uid, "object": "chat.completion", "created": ts,
                "model": model,
                "choices": [{"index": 0, "message": {"role": "assistant", "content": msg.get("content", "")}, "finish_reason": finish}],
                "usage": d.get("usage", {}),
            }
            d = json.dumps(resp).encode()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(d)))
            self.end_headers()
            self.wfile.write(d)
            self.wfile.flush()
            sys.stderr.write(f"[v9] DONE non-stream {dt:.1f}s\n")
            return

        # Streaming client: return SSE format with all content in one chunk
        # OpenAI-compatible format: each chunk has the SAME id, created, model
        # First chunk: role
        # Content chunks: actual text
        # Last chunk: finish_reason
        # [DONE] marker
        self.send_response(200)
        self.send_header("Content-Type", "text/event-stream")
        self.send_header("Cache-Control", "no-cache")
        self.send_header("Transfer-Encoding", "chunked")
        self.end_headers()

        def wr(s):
            d = s.encode() if isinstance(s, str) else s
            self.wfile.write(f"{len(d):x}\r\n".encode())
            self.wfile.write(d)
            self.wfile.write(b"\r\n")
            self.wfile.flush()

        content = msg.get("content", "")
        wr(f"data: " + json.dumps({
            "id": uid, "object": "chat.completion.chunk", "created": ts,
            "model": model,
            "choices": [{"index": 0, "delta": {"role": "assistant", "content": ""}, "finish_reason": None}]
        }) + "\n\n")
        wr(f"data: " + json.dumps({
            "id": uid, "object": "chat.completion.chunk", "created": ts,
            "model": model,
            "choices": [{"index": 0, "delta": {"content": content}, "finish_reason": finish}]
        }) + "\n\n")
        wr("data: [DONE]\n\n")
        self.wfile.write(b"0\r\n\r\n")
        self.wfile.flush()
        sys.stderr.write(f"[v9] DONE stream {dt:.1f}s content={len(content)}b\n")


if __name__ == "__main__":
    if not KEY:
        print("KEY missing", file=sys.stderr)
        sys.exit(1)
    print(f"[v9] :{PORT} (upstream non-stream, SSE wrap)", file=sys.stderr)
    ThreadingHTTPServer(("127.0.0.1", PORT), H).serve_forever()
