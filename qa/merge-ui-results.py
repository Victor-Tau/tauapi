#!/usr/bin/env python3
"""Merge screenshot results into UI_INVENTORY.csv and write a review summary.

Usage: merge-ui-results.py <UI_INVENTORY.csv> <reviewed.json> <results.json> [<results.json> ...]
Later result files override earlier ones for the same (id, shot).
reviewed.json: {"<id>": "manual visual review note", ...} for screenshots that
were actually opened and inspected.
"""
import csv
import json
import sys

inv_path, reviewed_path, *result_paths = sys.argv[1:]
reviewed = json.load(open(reviewed_path))
results = {}
for rp in result_paths:
    for r in json.load(open(rp)):
        results[(r["id"], r["shot"])] = {**r, "_dir": rp.rsplit("/", 2)[-2]}

rows = list(csv.DictReader(open(inv_path)))


def verdict(r):
    if r is None:
        return "not captured"
    ok_path = r["path_ok"] or (r.get("settled_path") is not None)
    if r["status"] != "ok":
        return "nav error"
    if not ok_path:
        return f"redirected to {r['final_path']}"
    if r.get("marker_visible") is False:
        return "rendered; marker off-screen"
    if r.get("overflow_x", 0) > 0:
        return f"overflow-x {r['overflow_x']}px"
    return "pass"


summary = {"pass": 0, "issues": []}
for row in rows:
    rid = row["id"]
    cols = {"desktop_light": "light-desktop", "desktop_dark": "dark-desktop", "mobile": "light-mobile"}
    files = []
    for col, shot in cols.items():
        r = results.get((rid, shot))
        v = verdict(r)
        row[col] = v
        if r:
            files.append(f"{r['_dir']}/{r['file']}")
        if v == "pass":
            summary["pass"] += 1
        else:
            summary["issues"].append(f"{rid} {shot}: {v}")
    extra = [s for (i, s) in results if i == rid and s not in cols.values()]
    if extra:
        row["mobile"] += " (+" + ",".join(sorted(extra)) + ")"
    row["flat_status"] = "flattened (shared tokens/primitives + feature pass)"
    note = reviewed.get(rid)
    row["evidence"] = "; ".join(files[:1]) + (f" | reviewed: {note}" if note else "")
with open(inv_path, "w", newline="") as fh:
    w = csv.DictWriter(fh, fieldnames=list(rows[0].keys()))
    w.writeheader()
    w.writerows(rows)
print(json.dumps({"rows": len(rows), "shots_pass": summary["pass"], "issues": summary["issues"]}, indent=1))
