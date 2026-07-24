#!/usr/bin/env python3
"""Debug proxy: just log what opencode sends, no transformation."""
import json
import os
import sys
import uuid
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer


class H(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        sys.stderr.write("[debug] " + (fmt % args) + "\n")

    def _send(self, status, body, ct="application/json"):
        if isinstance(body, (dict, list)):
            payload = json.dumps(body).encode()
        else:
            payload = body if isinstance(body, bytes) else str(body).encode()
        self.send_response(status)
        self.send_header("Content-Type", ct)
        self.send_header("Content-Length", str(len(payload)))
        self.send_header("Connection", "close")
        self.end_headers()
        self.wfile.write(payload)
        self.wfile.flush()

    def do_GET(self):
        self._send(200, {"object": "list", "data": [
            {"id": "kimi-k3", "object": "model", "owned_by": "moonshot"}
        ]})

    def do_POST(self):
        length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(length)
        try:
            data = json.loads(body)
            print(f"\n[debug] ===== POST {self.path} =====")
            print(f"[debug] HEADERS:")
            for k, v in self.headers.items():
                print(f"[debug]   {k}: {v[:200]}")
            print(f"[debug] BODY:")
            print(json.dumps(data, indent=2)[:3000])
        except Exception as e:
            print(f"[debug] RAW: {body[:500]}")
        # Return a simple response
        self._send(200, {
            "id": f"chatcmpl-{uuid.uuid4().hex[:24]}",
            "object": "chat.completion",
            "created": 1700000000,
            "model": data.get("model", "kimi-k3") if isinstance(data, dict) else "kimi-k3",
            "choices": [{
                "index": 0,
                "message": {"role": "assistant", "content": "Hello! Test response."},
                "finish_reason": "stop"
            }],
            "usage": {"prompt_tokens": 10, "completion_tokens": 3, "total_tokens": 13}
        })


if __name__ == "__main__":
    server = ThreadingHTTPServer(("127.0.0.1", 9876), H)
    print("[debug] Listening on 9876 (will LOG but NOT forward)", file=sys.stderr)
    server.serve_forever()
