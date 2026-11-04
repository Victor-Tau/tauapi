"""Controllable mock OpenAI-compatible upstream for the isolated QA stack ONLY.

Never deployed in production (compose profile "qa", internal network, no host
port). Behaviour is selected by the requested model name:
  mock-fast           non-stream / stream with 3 chunks, no delay
  mock-slow-<secs>    SSE stream emitting one chunk per second for <secs> seconds
  mock-error          upstream 500 with OpenAI-style error body
WebSocket /v1/realtime: sends a session.created event, then one event per
second until the client closes (used for drain-boundary evidence).
Standard library only.
"""
import base64
import hashlib
import json
import socket
import struct
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

WS_GUID = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"


def chunk(model, text, finish=None):
    return {
        "id": "chatcmpl-mock", "object": "chat.completion.chunk", "created": int(time.time()),
        "model": model,
        "choices": [{"index": 0, "delta": {"content": text} if text else {}, "finish_reason": finish}],
    }


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, fmt, *args):
        print("mock:", fmt % args, flush=True)

    def _json(self, code, obj):
        body = json.dumps(obj).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if self.path.startswith("/v1/realtime"):
            return self._websocket()
        if self.path.startswith("/v1/models"):
            return self._json(200, {"object": "list", "data": [
                {"id": m, "object": "model", "owned_by": "mock"} for m in ("mock-fast", "mock-slow-20", "mock-error")]})
        self._json(404, {"error": {"message": "not found", "type": "invalid_request_error"}})

    def do_POST(self):
        length = int(self.headers.get("Content-Length") or 0)
        req = json.loads(self.rfile.read(length) or b"{}")
        model = req.get("model", "mock-fast")
        if not self.path.startswith("/v1/chat/completions"):
            return self._json(404, {"error": {"message": "not found"}})
        if model == "mock-error":
            return self._json(500, {"error": {"message": "mock upstream failure", "type": "server_error"}})
        seconds = 0
        if model.startswith("mock-slow-"):
            seconds = max(1, min(600, int(model.rsplit("-", 1)[1])))
        if not req.get("stream"):
            return self._json(200, {
                "id": "chatcmpl-mock", "object": "chat.completion", "created": int(time.time()), "model": model,
                "choices": [{"index": 0, "message": {"role": "assistant", "content": "mock reply"}, "finish_reason": "stop"}],
                "usage": {"prompt_tokens": 5, "completion_tokens": 2, "total_tokens": 7}})
        self.send_response(200)
        self.send_header("Content-Type", "text/event-stream")
        self.send_header("Cache-Control", "no-cache")
        self.send_header("Connection", "close")
        self.end_headers()
        n = seconds if seconds else 3
        try:
            for i in range(n):
                self.wfile.write(f"data: {json.dumps(chunk(model, f'tick {i + 1} at {time.time():.3f} '))}\n\n".encode())
                self.wfile.flush()
                if seconds:
                    time.sleep(1)
            final = chunk(model, "", "stop")
            final["usage"] = {"prompt_tokens": 5, "completion_tokens": n, "total_tokens": 5 + n}
            self.wfile.write(f"data: {json.dumps(final)}\n\ndata: [DONE]\n\n".encode())
            self.wfile.flush()
        except (BrokenPipeError, ConnectionResetError):
            pass
        self.close_connection = True

    # --- minimal RFC 6455 server -----------------------------------------
    def _websocket(self):
        key = self.headers.get("Sec-WebSocket-Key")
        if not key or self.headers.get("Upgrade", "").lower() != "websocket":
            return self._json(400, {"error": {"message": "websocket upgrade required"}})
        accept = base64.b64encode(hashlib.sha1((key + WS_GUID).encode()).digest()).decode()
        self.send_response(101)
        self.send_header("Upgrade", "websocket")
        self.send_header("Connection", "Upgrade")
        self.send_header("Sec-WebSocket-Accept", accept)
        self.end_headers()
        self.wfile.flush()
        sock = self.connection
        stop = threading.Event()

        def send(obj):
            data = json.dumps(obj).encode()
            hdr = bytes([0x81])
            if len(data) < 126:
                hdr += bytes([len(data)])
            elif len(data) < 65536:
                hdr += bytes([126]) + struct.pack(">H", len(data))
            else:
                hdr += bytes([127]) + struct.pack(">Q", len(data))
            sock.sendall(hdr + data)

        def reader():
            try:
                while not stop.is_set():
                    head = sock.recv(2)
                    if len(head) < 2:
                        break
                    opcode = head[0] & 0x0F
                    ln = head[1] & 0x7F
                    if ln == 126:
                        ln = struct.unpack(">H", sock.recv(2))[0]
                    elif ln == 127:
                        ln = struct.unpack(">Q", sock.recv(8))[0]
                    mask = sock.recv(4) if head[1] & 0x80 else b""
                    payload = b""
                    while len(payload) < ln:
                        part = sock.recv(ln - len(payload))
                        if not part:
                            break
                        payload += part
                    if opcode == 0x8:
                        break
            except OSError:
                pass
            stop.set()

        threading.Thread(target=reader, daemon=True).start()
        try:
            send({"type": "session.created", "session": {"id": "sess_mock", "model": "mock-realtime"}})
            i = 0
            while not stop.is_set():
                i += 1
                send({"type": "mock.tick", "n": i, "t": time.time()})
                stop.wait(1)
            sock.sendall(bytes([0x88, 0x00]))
        except OSError:
            pass
        self.close_connection = True


if __name__ == "__main__":
    srv = ThreadingHTTPServer(("0.0.0.0", 8080), Handler)
    srv.daemon_threads = True
    print("mock upstream listening on :8080", flush=True)
    srv.serve_forever()
