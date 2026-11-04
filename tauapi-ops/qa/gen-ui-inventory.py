#!/usr/bin/env python3
"""Generate UI_INVENTORY seed (JSON for the screenshot runner + CSV for review)
from the real frontend sources: route tree fullPaths, section registries
(id + titleKey), and role guards in route files.

Usage: gen-ui-inventory.py <tauapi-fe dir> <out.json> <out.csv>
"""
import csv
import json
import os
import re
import sys

fe, out_json, out_csv = sys.argv[1:4]
src = os.path.join(fe, "src")


def sections(rel):
    text = open(os.path.join(src, rel)).read().replace("\n", " ")
    rows = re.findall(r"id: '([a-z0-9-]+)',\s*titleKey: '([^']+)'(.{0,120})", text)
    return [(i, t, "adminOnly: true" in rest) for i, t, rest in rows]


SECTION_ROUTES = {
    "/dashboard": "features/dashboard/section-registry.tsx",
    "/models": "features/models/section-registry.tsx",
    "/usage-logs": "features/usage-logs/section-registry.tsx",
}
for cat in ("auth", "billing", "content", "models", "operations", "request-policies", "security", "site"):
    SECTION_ROUTES[f"/system-settings/{cat}"] = f"features/system-settings/{cat}/section-registry.tsx"

ROLE = {
    "/channels": "admin", "/models": "admin", "/redemption-codes": "admin", "/subscriptions": "admin",
    "/users": "admin", "/system-info": "root", "/system-settings": "root", "/task-plugins": "root",
}
SHOTS_FULL = ["light-desktop", "dark-desktop", "light-mobile"]
SHOTS_REP = ["light-desktop", "dark-desktop", "light-mobile", "dark-mobile", "light-tablet"]

rows = []


def add(rid, url, name, role, marker, shots=SHOTS_FULL, interactions="", flag="", param="", ext="", expect=None, early=None):
    row = {"id": rid, "url": url, "name": name, "role": role, "marker": marker, "shots": shots,
           "interactions": interactions, "feature_flag": flag, "param_source": param,
           "external": ext, "expect_path": expect}
    if early:
        row["early"] = early
    rows.append(row)


# Public
add("home", "/", "Home", "anon", None, SHOTS_REP, "nav, CTA, theme switch")
add("pricing", "/pricing", "Model pricing", "anon", "Pricing", SHOTS_REP, "search, filters, view toggle")
add("pricing-detail", "/pricing/mock-fast", "Model pricing detail", "anon", "mock-fast", param="model id")
add("rankings", "/rankings", "Rankings", "anon", None, interactions="period tabs, charts")
add("about", "/about", "About", "anon", None)
add("privacy", "/privacy-policy", "Privacy policy", "anon", None)
add("terms", "/user-agreement", "User agreement", "anon", None)
# Auth
add("sign-in", "/sign-in", "Sign in", "anon", "Sign in", SHOTS_REP, "form validation, password toggle")
add("sign-up", "/sign-up", "Sign up (registration disabled in prod)", "anon", None, flag="RegisterEnabled")
add("forgot-password", "/forgot-password", "Forgot password", "anon", None, ext="SMTP")
add("reset", "/user/reset?email=qa%40example.com&token=invalid", "Password reset confirm", "anon", None, expect="/user/reset", ext="SMTP")
add("otp", "/otp", "OTP (no pending challenge -> sign-in)", "anon", None, early=400)
add("oauth-cb", "/oauth/github?code=invalid&state=invalid", "OAuth callback (waiting/failure state)", "anon", None, expect="/oauth/github", ext="OAuth provider", early=600)
# Errors
for code in ("401", "403", "404", "503"):
    add(f"err-{code}", f"/{code}", f"Error {code}", "anon", code)
# Upstream /500 renders GeneralError without a status number.
add("err-500", "/500", "Error 500 (general error)", "anon", "Something went wrong")
# Console
add("keys", "/keys", "API Keys", "user", "qa-token" if False else None, SHOTS_REP, "create/edit dialogs, copy, batch")
add("playground", "/playground", "Playground", "admin", None, SHOTS_REP, "model select, send, stop, attachments")
add("wallet", "/wallet", "Wallet", "user", None, interactions="recharge form, redeem code", ext="payment gateway")
add("profile", "/profile", "Profile", "user", None, interactions="edit profile, check-in")
add("security", "/security", "Account security", "user", None, interactions="password, 2FA, passkey, sessions, access tokens")
# Admin
add("channels", "/channels", "Channels", "admin", "qa-mock", SHOTS_REP, "filters, create drawer, test, priority, batch")
add("redemption", "/redemption-codes", "Redemption codes", "admin", None)
add("subscriptions", "/subscriptions", "Subscriptions", "admin", None)
add("users", "/users", "Users", "admin", "qauser", interactions="create, edit, ban, batch")
add("system-info", "/system-info", "System info", "root", None)
add("task-plugins", "/task-plugins", "Task plugins", "root", None)
add("audit", "/usage-logs/audit", "Audit logs", "admin", None)
# Dynamic sections
for base, reg in SECTION_ROUTES.items():
    for sid, title, admin_only in sections(reg):
        role = ROLE.get("/" + base.strip("/").split("/")[0], "user")
        if admin_only and role == "user":
            role = "admin"
        if base == "/usage-logs" or base == "/dashboard":
            role = "admin" if role == "user" else role
        add(f"{base.strip('/').replace('/', '-')}-{sid}", f"{base}/{sid}", f"{base} › {title}", role, title,
            param=f"{reg} id={sid}")
# Representative user-role views of shared pages
add("user-dashboard", "/dashboard/overview", "Dashboard overview (common user)", "user", "Overview")
add("user-logs", "/usage-logs/common", "Usage logs (common user)", "user", "Common Logs")

json.dump(rows, open(out_json, "w"), indent=1)
with open(out_csv, "w", newline="") as fh:
    w = csv.writer(fh)
    w.writerow(["id", "route_pattern", "example_url", "page_name", "role", "feature_flag", "param_source",
                "main_interactions", "flat_status", "desktop_light", "desktop_dark", "mobile", "evidence",
                "external_dependency"])
    for r in rows:
        pattern = r["url"].split("?")[0]
        for base in SECTION_ROUTES:
            if pattern.startswith(base + "/") and pattern.count("/") == base.count("/") + 1:
                pattern = base + "/$section"
        if pattern.startswith("/pricing/"):
            pattern = "/pricing/$modelId"
        if pattern.startswith("/oauth/"):
            pattern = "/oauth/$provider"
        w.writerow([r["id"], pattern, r["url"], r["name"], r["role"], r["feature_flag"], r["param_source"],
                    r["interactions"], "", "", "", "", "", r["external"]])
print(len(rows))
