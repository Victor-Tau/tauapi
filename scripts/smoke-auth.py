#!/usr/bin/env python3
"""Browser-session acceptance check against https://api.victor-tau.xyz.

Exercises the real cookie/session control plane through Nginx + TLS:
  wrong password -> rejected; login -> access token + Secure HttpOnly refresh
  cookie; protected admin DB read (/api/status/test); refresh with Origin
  (rotates); refresh WITHOUT Origin -> rejected by OriginGuard; logout; refresh
  after logout -> 401.

Usage (root, credentials read from /etc/tauapi/initial-admin.json):
  smoke-auth.py [--public]   (--public: connect to the public IP instead of loopback)
Prints a redacted JSON summary only. Exit 0 if every check passed, 1 otherwise.
"""
import http.client
import json
import socket
import ssl
import sys

DOMAIN = "api.victor-tau.xyz"
ORIGIN = f"https://{DOMAIN}"
CRED = "/etc/tauapi/initial-admin.json"
PUBLIC = "--public" in sys.argv


class Conn(http.client.HTTPSConnection):
    def connect(self):
        host = DOMAIN if PUBLIC else "127.0.0.1"
        sock = socket.create_connection((host, 443), self.timeout)
        self.sock = self._context.wrap_socket(sock, server_hostname=DOMAIN)


def call(method, path, body=None, headers=None):
    c = Conn(DOMAIN, 443, timeout=30, context=ssl.create_default_context())
    h = {"Accept": "application/json", "User-Agent": "tauapi-smoke-auth/1"}
    if body is not None:
        h["Content-Type"] = "application/json"
        body = json.dumps(body).encode()
    h.update(headers or {})
    c.request(method, path, body=body, headers=h)
    r = c.getresponse()
    raw = r.read()
    cookies = r.headers.get_all("Set-Cookie") or []
    c.close()
    try:
        data = json.loads(raw)
    except ValueError:
        data = None
    return r.status, data, cookies


def cookie_jar(cookies, jar):
    for c in cookies:
        pair = c.split(";", 1)[0]
        name, _, value = pair.partition("=")
        if value:
            jar[name] = value
        else:
            jar.pop(name, None)
    return jar


def header(jar):
    return "; ".join(f"{k}={v}" for k, v in jar.items())


def main():
    creds = json.load(open(CRED))
    results = {}

    st, data, _ = call("POST", "/api/user/login", {"username": creds["username"], "password": "wrong-" + "x" * 12})
    results["wrong_password_rejected"] = not (isinstance(data, dict) and data.get("success"))

    st, data, cookies = call("POST", "/api/user/login", {"username": creds["username"], "password": creds["password"]})
    ok = st == 200 and isinstance(data, dict) and data.get("success")
    results["login"] = bool(ok)
    if not ok:
        print(json.dumps(results))
        return 1
    token = data["data"]["access_token"]
    sid = data["data"]["session"]["sid"]
    refresh_cookie = [c for c in cookies if "auth" in c.lower() or "refresh" in c.lower()]
    results["refresh_cookie_secure_httponly"] = any(
        "secure" in c.lower() and "httponly" in c.lower() for c in refresh_cookie)
    jar = cookie_jar(cookies, {})

    st, data, _ = call("GET", "/api/status/test", headers={"Authorization": f"Bearer {token}"})
    results["admin_db_check"] = st == 200 and isinstance(data, dict) and data.get("success") is True
    st, data, _ = call("GET", "/api/status/test")
    results["admin_db_check_requires_auth"] = st in (401, 403)

    st, data, _ = call("POST", "/api/user/auth/refresh", {}, {"Cookie": header(jar), "X-Auth-Session": sid})
    results["refresh_without_origin_rejected"] = st in (401, 403)

    st, data, cookies = call("POST", "/api/user/auth/refresh", {},
                             {"Cookie": header(jar), "Origin": ORIGIN, "X-Auth-Session": sid})
    rotated = st == 200 and isinstance(data, dict) and data.get("success")
    results["refresh_with_origin"] = bool(rotated)
    if rotated:
        old = dict(jar)
        cookie_jar(cookies, jar)
        results["refresh_rotated_cookie"] = old != jar
        token = data["data"]["access_token"]

    st, data, _ = call("GET", "/api/user/self", headers={"Authorization": f"Bearer {token}"})
    results["self_after_refresh"] = st == 200 and isinstance(data, dict) and data.get("success") is True

    st, data, cookies = call("POST", "/api/user/auth/logout", {},
                             {"Cookie": header(jar), "Origin": ORIGIN, "X-Auth-Session": sid,
                              "Authorization": f"Bearer {token}"})
    results["logout"] = st == 200 and isinstance(data, dict) and data.get("success") is True
    stale = dict(jar)
    cookie_jar(cookies, jar)

    st, _, _ = call("POST", "/api/user/auth/refresh", {}, {"Cookie": header(stale), "Origin": ORIGIN})
    results["refresh_after_logout_rejected"] = st == 401

    print(json.dumps({"target": "public" if PUBLIC else "loopback", **results}))
    return 0 if all(results.values()) else 1


if __name__ == "__main__":
    sys.exit(main())
