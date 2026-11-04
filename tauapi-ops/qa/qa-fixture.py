#!/usr/bin/env python3
"""Idempotent fixtures for the ISOLATED QA stack only (TAUAPI_ENV=qa).

Creates (if missing): a common user `qauser`, an OpenAI-compatible channel
`qa-mock` pointing to the internal mock upstream, and an unlimited API token
`qa-token` for the QA admin. Secrets are written to /etc/tauapi-qa (0600) and
never printed. Refuses to run against production.
"""
import json
import os
import secrets
import socket
import ssl
import string
import sys
import http.client

if os.environ.get("TAUAPI_ENV") != "qa":
    sys.exit("qa-fixture.py refuses to run outside TAUAPI_ENV=qa")
DOMAIN, PORT = "api.victor-tau.xyz", 8443
SECRETS = "/etc/tauapi-qa"
MOCK_MODELS = "mock-fast,mock-slow-5,mock-slow-20,mock-slow-90,mock-slow-200,mock-error,mock-realtime"


class Conn(http.client.HTTPSConnection):
    def connect(self):
        self.sock = self._context.wrap_socket(
            socket.create_connection(("127.0.0.1", PORT), self.timeout), server_hostname=DOMAIN)


def call(method, path, body=None, token=None):
    c = Conn(DOMAIN, PORT, timeout=30, context=ssl.create_default_context())
    h = {"Accept": "application/json"}
    if token:
        h["Authorization"] = f"Bearer {token}"
    if body is not None:
        h["Content-Type"] = "application/json"
        body = json.dumps(body).encode()
    c.request(method, path, body=body, headers=h)
    r = c.getresponse()
    raw = r.read()
    c.close()
    try:
        return r.status, json.loads(raw)
    except ValueError:
        return r.status, None


def save(name, obj):
    path = f"{SECRETS}/{name}"
    fd = os.open(path + ".tmp", os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(fd, "w") as fh:
        json.dump(obj, fh)
    os.replace(path + ".tmp", path)


def load(name):
    p = f"{SECRETS}/{name}"
    return json.load(open(p)) if os.path.exists(p) else None


def must(st, data, what):
    if not (st == 200 and isinstance(data, dict) and data.get("success") is not False):
        sys.exit(f"{what} failed: HTTP {st} {data.get('message') if isinstance(data, dict) else ''}")
    return data


admin = load("initial-admin.json")
st, data = call("POST", "/api/user/login", {"username": admin["username"], "password": admin["password"]})
tok = must(st, data, "admin login")["data"]["access_token"]
out = {}

user = load("qa-user.json")
if user is None:
    pw = "".join(secrets.choice(string.ascii_letters + string.digits) for _ in range(24))
    user = {"username": "qauser", "password": pw}
    save("qa-user.json", user)
st, data = call("GET", "/api/user/search?keyword=qauser", token=tok)
items = (data or {}).get("data") or {}
items = items.get("items", items) if isinstance(items, dict) else items
if not any(u.get("username") == "qauser" for u in (items or [])):
    must(*call("POST", "/api/user/", {"username": "qauser", "password": user["password"],
                                      "display_name": "QA User", "role": 1}, tok), "create qauser")
    out["qauser"] = "created"
else:
    out["qauser"] = "exists"

st, data = call("GET", "/api/channel/search?keyword=qa-mock", token=tok)
chans = (data or {}).get("data") or {}
chans = chans.get("items", chans) if isinstance(chans, dict) else chans
if not any(c.get("name") == "qa-mock" for c in (chans or [])):
    must(*call("POST", "/api/channel/", {"mode": "single", "channel": {
        "name": "qa-mock", "type": 1, "key": "sk-mock-not-a-real-key",
        "base_url": "http://mock-upstream:8080", "models": MOCK_MODELS,
        "group": "default", "status": 1}}, tok), "create channel")
    out["channel"] = "created"
else:
    ch = next(c for c in chans if c.get("name") == "qa-mock")
    if ch.get("models") != MOCK_MODELS:
        must(*call("PUT", "/api/channel/", {"id": ch["id"], "models": MOCK_MODELS}, tok), "update channel models")
        out["channel"] = "models-updated"
    else:
        out["channel"] = "exists"

if load("qa-token.json") is None:
    must(*call("POST", "/api/token/", {"name": "qa-token", "expired_time": -1, "remain_quota": 0,
                                       "unlimited_quota": True, "group": ""}, tok), "create token")
    st, data = call("GET", "/api/token/?p=1&size=50", token=tok)
    items = (data or {}).get("data") or {}
    items = items.get("items", items) if isinstance(items, dict) else items
    tid = next(t["id"] for t in items if t.get("name") == "qa-token")
    st, data = call("POST", f"/api/token/{tid}/key", {}, tok)
    key = must(st, data, "token key")["data"]
    key = key.get("key", key) if isinstance(key, dict) else key
    save("qa-token.json", {"id": tid, "key": key if str(key).startswith("sk-") else f"sk-{key}"})
    out["token"] = "created"
else:
    out["token"] = "exists"
print(json.dumps(out))
