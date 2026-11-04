#!/usr/bin/env python3
"""Session persistence across backend restarts + trusted-proxy client IP (QA).

1. log in through Nginx (QA :8443), keep refresh cookie + sid in memory
2. report the client IP the backend recorded for the session (must not be the
   Docker bridge gateway, which would mean TRUSTED_PROXIES is wrong)
3. restart BOTH QA backend containers (docker compose restart)
4. refresh with Origin -> must succeed (DB-backed session survives restart)
5. /api/user/self with the new token, then logout
Never prints tokens/cookies. Run as root with TAUAPI_ENV=qa.
"""
import http.client
import json
import os
import socket
import ssl
import subprocess
import sys
import time

if os.environ.get("TAUAPI_ENV") != "qa":
    sys.exit("QA only")
DOMAIN, PORT = "api.victor-tau.xyz", 8443
ORIGIN = f"https://{DOMAIN}:{PORT}"
creds = json.load(open("/etc/tauapi-qa/initial-admin.json"))


class Conn(http.client.HTTPSConnection):
    def connect(self):
        self.sock = self._context.wrap_socket(
            socket.create_connection(("127.0.0.1", PORT), self.timeout), server_hostname=DOMAIN)


def call(method, path, body=None, headers=None):
    c = Conn(DOMAIN, PORT, timeout=30, context=ssl.create_default_context())
    h = {"Accept": "application/json"}
    if body is not None:
        h["Content-Type"] = "application/json"
        body = json.dumps(body).encode()
    h.update(headers or {})
    c.request(method, path, body=body, headers=h)
    r = c.getresponse()
    raw = r.read()
    ck = r.headers.get_all("Set-Cookie") or []
    c.close()
    try:
        return r.status, json.loads(raw), ck
    except ValueError:
        return r.status, None, ck


def jar_update(jar, cookies):
    for c in cookies:
        name, _, value = c.split(";", 1)[0].partition("=")
        if value:
            jar[name] = value
        else:
            jar.pop(name, None)


res = {}
st, d, ck = call("POST", "/api/user/login", {"username": creds["username"], "password": creds["password"]})
assert st == 200 and d.get("success"), f"login failed {st}"
sid = d["data"]["session"]["sid"]
res["session_ip_recorded"] = d["data"]["session"].get("ip")
res["session_ip_is_docker_gateway"] = str(res["session_ip_recorded"]).startswith("172.30.")
jar = {}
jar_update(jar, ck)
cookie = lambda: "; ".join(f"{k}={v}" for k, v in jar.items())

compose = ["docker", "compose", "-p", "tauapi-qa", "-f", "/srv/tauapi-qa/stack/compose.yml",
           "--env-file", "/srv/tauapi-qa/stack/images.env", "--profile", "qa"]
before = subprocess.run(compose + ["ps", "-q", "backend-master", "backend-slave"], capture_output=True, text=True).stdout.split()
subprocess.run(compose + ["restart", "backend-master", "backend-slave"], check=True, capture_output=True)
for _ in range(60):
    ok = 0
    for port in (3101, 3102):
        try:
            c = http.client.HTTPConnection("127.0.0.1", port, timeout=3)
            c.request("GET", "/api/status")
            ok += c.getresponse().status == 200
            c.close()
        except OSError:
            pass
    if ok == 2:
        break
    time.sleep(2)
started = subprocess.run(["docker", "inspect", "-f", "{{.State.StartedAt}}"] + before, capture_output=True, text=True).stdout.split()
res["backends_restarted"] = len(started) == 2

st, d, ck = call("POST", "/api/user/auth/refresh", {}, {"Cookie": cookie(), "Origin": ORIGIN, "X-Auth-Session": sid})
res["refresh_after_restart"] = st == 200 and bool(d and d.get("success"))
token = d["data"]["access_token"] if res["refresh_after_restart"] else None
jar_update(jar, ck)
if token:
    st, d, _ = call("GET", "/api/user/self", headers={"Authorization": f"Bearer {token}"})
    res["self_after_restart"] = st == 200 and d.get("success") is True
    st, d, _ = call("POST", "/api/user/auth/logout", {}, {"Cookie": cookie(), "Origin": ORIGIN,
                                                          "X-Auth-Session": sid, "Authorization": f"Bearer {token}"})
    res["logout"] = st == 200
print(json.dumps(res))
sys.exit(0 if res.get("refresh_after_restart") and res.get("self_after_restart") and not res["session_ip_is_docker_gateway"] else 1)
