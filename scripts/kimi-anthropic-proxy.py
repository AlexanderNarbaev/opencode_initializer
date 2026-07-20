#!/usr/bin/env python3
"""
Kimi/Moonshot Anthropic-compatible proxy for opencode.
Translates OpenAI /v1/chat/completions requests to Moonshot /anthropic/v1/messages.
Listens on localhost:9876 by default.

Why: opencode AI SDK + @ai-sdk/openai-compatible sends temperature:0 (which Moonshot
rejects) and reasoning consumes all output_tokens (leaving no room for content).
The Anthropic-compatible endpoint accepts temperature:1 and supports thinking.budget_tokens
to constrain reasoning budget. This proxy lets opencode use the familiar OpenAI
protocol while we apply Moonshot-specific defaults server-side.
"""
import json
import os
import sys
import time
import uuid
import urllib.error
import urllib.request
from http.server import BaseHTTPRequestHandler, HTTPServer

MOONSHOT_API_KEY = os.environ.get("MOONSHOT_API_KEY", "")
ANTHROPIC_BASE = os.environ.get("ANTHROPIC_BASE", "https://api.moonshot.ai/anthropic")
PORT = int(os.environ.get("KIMI_PROXY_PORT", "9876"))


def translate_openai_to_anthropic(body):
    model = body.get("model", "kimi-k3")
    max_tokens = int(body.get("max_tokens", 4096))
    temperature = body.get("temperature", 1)

    msgs = []
    for m in body.get("messages", []):
        msgs.append({"role": m.get("role"), "content": m.get("content", "")})

    anth = {
        "model": model,
        "max_tokens": max_tokens,
        "messages": msgs,
        "temperature": temperature,
    }

    # Constrain reasoning budget so model has tokens left for actual content.
    thinking_budget = max(256, min(4096, max_tokens // 4))
    anth["thinking"] = {"type": "enabled", "budget_tokens": thinking_budget}

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
    if t == "message_delta":
        sr = evt.get("delta", {}).get("stop_reason")
        return {"id": msg_id, "object": "chat.completion.chunk", "created": int(time.time()),
                "model": model, "choices": [{"index": 0, "delta": {}, "finish_reason": sr}]}
    if t == "message_stop":
        return "[DONE]"
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


class Handler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        sys.stderr.write("[kimi-proxy] " + (format % args) + "\n")

    def _send(self, status, body, content_type="application/json"):
        if isinstance(body, (dict, list)):
            payload = json.dumps(body).encode()
        elif isinstance(body, str):
            payload = body.encode()
        else:
            payload = body
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def do_GET(self):
        if self.path == "/v1/models":
            return self._send(200, {"object": "list", "data": [
                {"id": "kimi-k3", "object": "model", "owned_by": "moonshot"},
                {"id": "kimi-k2.7-code", "object": "model", "owned_by": "moonshot"},
                {"id": "kimi-k2.7-code-highspeed", "object": "model", "owned_by": "moonshot"},
            ]})
        return self._send(404, {"error": "not found"})

    def do_POST(self):
        if not self.path.startswith("/v1/chat/completions"):
            return self._send(404, {"error": "not found"})
        length = int(self.headers.get("Content-Length", 0))
        try:
            body = json.loads(self.rfile.read(length))
        except Exception as e:
            return self._send(400, {"error": f"bad json: {e}"})

        anth_body = translate_openai_to_anthropic(body)
        model = anth_body["model"]
        stream = body.get("stream", False)

        req = urllib.request.Request(
            f"{ANTHROPIC_BASE}/v1/messages",
            data=json.dumps(anth_body).encode(),
            headers={"Content-Type": "application/json", "x-api-key": MOONSHOT_API_KEY,
                     "anthropic-version": "2023-06-01"},
        )
        try:
            with urllib.request.urlopen(req, timeout=300) as resp:
                if stream:
                    self.send_response(200)
                    self.send_header("Content-Type", "text/event-stream")
                    self.send_header("Cache-Control", "no-cache")
                    self.end_headers()
                    msg_id = f"chatcmpl-{uuid.uuid4().hex[:24]}"
                    for line in resp:
                        line = line.decode().strip()
                        if not line or not line.startswith("data: "):
                            continue
                        data = line[6:]
                        if data == "[DONE]":
                            self.wfile.write(b"data: [DONE]\n\n")
                            self.wfile.flush()
                            break
                        try:
                            evt = json.loads(data)
                        except Exception:
                            continue
                        out = anthropic_chunk_to_openai(evt, msg_id, model)
                        if out is None:
                            continue
                        if out == "[DONE]":
                            self.wfile.write(b"data: [DONE]\n\n")
                            self.wfile.flush()
                            break
                        self.wfile.write(f"data: {json.dumps(out)}\n\n".encode())
                        self.wfile.flush()
                    return
                data = json.loads(resp.read())
                return self._send(200, anthropic_response_to_openai(data, model))
        except urllib.error.HTTPError as e:
            try:
                return self._send(e.code, json.loads(e.read()))
            except Exception:
                return self._send(e.code, {"error": str(e)})
        except Exception as e:
            return self._send(500, {"error": str(e)})


def main():
    if not MOONSHOT_API_KEY:
        print("ERROR: MOONSHOT_API_KEY env var required", file=sys.stderr)
        sys.exit(1)
    server = HTTPServer(("127.0.0.1", PORT), Handler)
    print(f"[kimi-proxy] Listening on http://127.0.0.1:{PORT}", file=sys.stderr)
    print(f"[kimi-proxy] Forwarding to {ANTHROPIC_BASE}", file=sys.stderr)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()
