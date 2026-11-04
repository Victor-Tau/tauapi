#!/usr/bin/env python3
"""WebSocket probe for /v1/realtime through Nginx + TLS (QA only by default).

Usage: ws-probe.py --seconds N [--port 8443] [--model mock-realtime]
Reads the API key from /etc/tauapi-qa/qa-token.json (never printed). Prints one
JSON line per received event with its arrival time, then a summary including
how the connection ended (clean close / reset / timeout). Standard library only.
"""
import argparse
import base64
import json
import os
import socket
import ssl
import struct
import sys
import time

ap = argparse.ArgumentParser()
ap.add_argument("--seconds", type=float, default=10)
ap.add_argument("--port", type=int, default=8443)
ap.add_argument("--model", default="mock-realtime")
ap.add_argument("--quiet", action="store_true")
a = ap.parse_args()
DOMAIN = "api.victor-tau.xyz"
key = json.load(open("/etc/tauapi-qa/qa-token.json"))["key"]

raw = socket.create_connection(("127.0.0.1", a.port), timeout=10)
s = ssl.create_default_context().wrap_socket(raw, server_hostname=DOMAIN)
wskey = base64.b64encode(os.urandom(16)).decode()
req = (f"GET /v1/realtime?model={a.model} HTTP/1.1\r\nHost: {DOMAIN}:{a.port}\r\n"
       f"Upgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Key: {wskey}\r\n"
       f"Sec-WebSocket-Version: 13\r\nAuthorization: Bearer {key}\r\n"
       f"OpenAI-Beta: realtime=v1\r\n\r\n")
s.sendall(req.encode())
resp = b""
while b"\r\n\r\n" not in resp:
    chunk = s.recv(4096)
    if not chunk:
        break
    resp += chunk
head, _, rest = resp.partition(b"\r\n\r\n")
status = head.split(b"\r\n", 1)[0].decode()
if " 101 " not in status + " ":
    print(json.dumps({"upgrade": status, "body": rest[:200].decode(errors="replace")}))
    sys.exit(1)
start = time.time()
buf = rest
events = 0
end = "timeout"
s.settimeout(2)


def need(n):
    global buf
    while len(buf) < n:
        part = s.recv(65536)
        if not part:
            raise ConnectionResetError("eof")
        buf += part
    out, buf = buf[:n], buf[n:]
    return out


try:
    while time.time() - start < a.seconds:
        try:
            h = need(2)
        except socket.timeout:
            continue
        op, ln = h[0] & 0x0F, h[1] & 0x7F
        if ln == 126:
            ln = struct.unpack(">H", need(2))[0]
        elif ln == 127:
            ln = struct.unpack(">Q", need(8))[0]
        payload = need(ln)
        if op == 0x8:
            code = struct.unpack(">H", payload[:2])[0] if len(payload) >= 2 else None
            end = f"server-close code={code}"
            break
        if op == 0x1:
            events += 1
            if not a.quiet:
                ev = json.loads(payload)
                print(json.dumps({"t": round(time.time() - start, 2), "type": ev.get("type"), "n": ev.get("n")}))
    else:
        end = "client-close"
        mask = os.urandom(4)
        s.sendall(bytes([0x88, 0x80]) + mask)
except (ConnectionResetError, BrokenPipeError, ssl.SSLError, OSError) as e:
    end = f"reset ({type(e).__name__})"
print(json.dumps({"upgrade": status, "events": events, "duration": round(time.time() - start, 2), "end": end}))
