#!/usr/bin/env python3
"""Idempotent first-run initialisation of the production New API instance.

Runs on the server as root, talking to Nginx over the loopback HTTPS channel
(real TLS, real certificate, Host/SNI api.victor-tau.xyz, connection source
127.0.0.1) so it works while the public site is still in maintenance mode.

Steps (GOAL §13.3):
  1. GET /api/setup and read status + root_init separately.
  2. Create the root user only when none exists, with a password that was
     first saved atomically to /etc/newapi/initial-admin.json (0600). Reruns
     reuse that file and never generate a second password.
  3. SelfUseModeEnabled=true, DemoSiteEnabled=false.
  4. Log in, set ServerAddress=https://api.victor-tau.xyz, RegisterEnabled=false.
  5. Verify the public status endpoint reflects those values, then log out.

Secrets never appear in argv, stdout or logs. Exit codes: 0 ok, 3 missing
credentials (manual recovery needed), 4 API failure.
"""
import http.client
import json
import os
import secrets
import socket
import ssl
import string
import sys
import tempfile
import time

DOMAIN = "api.victor-tau.xyz"
ORIGIN = f"https://{DOMAIN}"
CRED_PATH = "/etc/newapi/initial-admin.json"
USERNAME = "admin"


class LoopbackHTTPS(http.client.HTTPSConnection):
    """HTTPS to 127.0.0.1:443 while validating the certificate for DOMAIN."""

    def connect(self):
        sock = socket.create_connection(("127.0.0.1", 443), self.timeout)
        self.sock = self._context.wrap_socket(sock, server_hostname=DOMAIN)


def request(method, path, body=None, headers=None):
    ctx = ssl.create_default_context()
    conn = LoopbackHTTPS(DOMAIN, 443, timeout=30, context=ctx)
    hdrs = {"Accept": "application/json", "User-Agent": "newapi-bootstrap-admin/1"}
    if body is not None:
        hdrs["Content-Type"] = "application/json"
        body = json.dumps(body).encode()
    hdrs.update(headers or {})
    conn.request(method, path, body=body, headers=hdrs)
    resp = conn.getresponse()
    raw = resp.read()
    set_cookies = resp.headers.get_all("Set-Cookie") or []
    conn.close()
    try:
        data = json.loads(raw)
    except ValueError:
        data = None
    return resp.status, data, set_cookies


def log(msg):
    print(f"[bootstrap-admin] {msg}", file=sys.stderr)


def fail(msg, code=4):
    log("ERROR: " + msg)
    sys.exit(code)


def ok(status, data):
    return status == 200 and isinstance(data, dict) and data.get("success") is True


def save_credentials(password):
    d = os.path.dirname(CRED_PATH)
    fd, tmp = tempfile.mkstemp(prefix=".initial-admin.", dir=d)
    try:
        os.fchmod(fd, 0o600)
        with os.fdopen(fd, "w") as fh:
            json.dump({"username": USERNAME, "password": password,
                       "created_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
                       "note": "Initial New API root administrator. Change after first login."}, fh)
            fh.write("\n")
            fh.flush()
            os.fsync(fh.fileno())
        os.replace(tmp, CRED_PATH)
    except BaseException:
        if os.path.exists(tmp):
            os.unlink(tmp)
        raise


def load_credentials():
    if not os.path.exists(CRED_PATH):
        return None
    st = os.stat(CRED_PATH)
    if st.st_mode & 0o077:
        os.chmod(CRED_PATH, 0o600)
    with open(CRED_PATH) as fh:
        return json.load(fh)


def main():
    if os.geteuid() != 0:
        fail("must run as root", 2)

    status, data, _ = request("GET", "/api/setup")
    if not ok(status, data):
        fail(f"GET /api/setup -> HTTP {status}")
    setup = data["data"]
    log(f"setup status={setup.get('status')} root_init={setup.get('root_init')} db={setup.get('database_type')}")

    creds = load_credentials()
    if not setup.get("status"):
        if setup.get("root_init"):
            if creds is None:
                fail("root user exists but setup is incomplete and no saved credentials: "
                     "manual admin access recovery required (not generating a new password)", 3)
        elif creds is None:
            alphabet = string.ascii_letters + string.digits
            password = "".join(secrets.choice(alphabet) for _ in range(32))
            save_credentials(password)
            creds = load_credentials()
            log(f"generated administrator credentials -> {CRED_PATH} (0600)")
        status, data, _ = request("POST", "/api/setup", {
            "username": creds["username"],
            "password": creds["password"],
            "confirmPassword": creds["password"],
            "SelfUseModeEnabled": True,
            "DemoSiteEnabled": False,
        })
        if not ok(status, data):
            fail(f"POST /api/setup -> HTTP {status} message={data.get('message') if isinstance(data, dict) else None}")
        log("POST /api/setup success")
        status, data, _ = request("GET", "/api/setup")
        # Upstream GetSetup short-circuits once setup is complete and no longer
        # computes root_init (it stays false), so root existence is proven by
        # the admin login below rather than by this field.
        if not (ok(status, data) and data["data"].get("status")):
            fail("setup did not report status=true after POST")
    elif creds is None:
        fail("system already initialised but credentials file is missing: cannot apply "
             "post-setup options without admin access", 3)

    # --- authenticated configuration ----------------------------------------
    status, data, cookies = request("POST", "/api/user/login",
                                    {"username": creds["username"], "password": creds["password"]})
    if not ok(status, data):
        fail(f"admin login -> HTTP {status} message={data.get('message') if isinstance(data, dict) else None}")
    token = data["data"]["access_token"]
    sid = data["data"].get("session", {}).get("sid", "")
    auth = {"Authorization": f"Bearer {token}"}
    log("admin login success (token not logged)")

    for key, value in (("ServerAddress", ORIGIN), ("RegisterEnabled", False)):
        status, data, _ = request("PUT", "/api/option/", {"key": key, "value": value}, auth)
        if not ok(status, data):
            fail(f"PUT /api/option/ {key} -> HTTP {status} message={data.get('message') if isinstance(data, dict) else None}")
        log(f"option {key} set")

    status, data, _ = request("GET", "/api/status")
    if not ok(status, data):
        fail(f"GET /api/status -> HTTP {status}")
    st = data["data"]
    checks = {
        "server_address": st.get("server_address") == ORIGIN,
        "register_enabled_false": st.get("register_enabled") is False,
        "self_use_mode_enabled": st.get("self_use_mode_enabled") is True,
        "demo_site_disabled": st.get("demo_site_enabled") in (False, None),
    }
    for name, passed in checks.items():
        log(f"verify {name}: {'ok' if passed else 'FAILED'}")
    if not all(checks.values()):
        fail("post-setup verification failed")

    # Close the bootstrap session (exercises logout with Secure cookie + Origin).
    cookie_pairs = "; ".join(c.split(";", 1)[0] for c in cookies)
    status, data, _ = request("POST", "/api/user/auth/logout", {}, {
        **auth, "Origin": ORIGIN, "Cookie": cookie_pairs, "X-Auth-Session": sid})
    log(f"bootstrap session logout HTTP {status} success={isinstance(data, dict) and data.get('success')}")
    print(json.dumps({"initialized": True, "admin_username": creds["username"],
                      "credentials_file": CRED_PATH, **checks}))
    return 0


if __name__ == "__main__":
    sys.exit(main())
