#!/usr/bin/env python3
"""Import a pinned upstream Git tree into the vendor/upstream branch of a split repo.

Usage (TauAPI monorepo):
  import-upstream.py --upstream /var/cache/tauapi/upstream --sha <full-sha> \
      --kind frontend|backend --repo /opt/tauapi --ref vendor/upstream-fe

The import branch keeps the split layout at its root (as the original
tauapi-fe / tauapi-be repositories had); main carries it under tauapi-fe/ or
tauapi-be/ and takes new imports with `git merge -X subtree=<dir>/`.

Behaviour:
  * Reads ONLY from the Git object database (git archive), never from a work tree.
  * Builds the mapped snapshot in a temp dir, stages it with a private index and
    commits it on refs/heads/vendor/upstream (linear history, parent = previous tip).
  * Identical source + mapping => no-op (exit 0, "unchanged").
  * Never touches main or the working tree, except --init-main on an empty repo
    which creates main from the first import.
  * Tags the import commit as upstream/<short-sha>.
Exit codes: 0 ok/no-op, 2 usage, 3 upstream object missing, 4 git failure.
"""
import argparse
import hashlib
import json
import os
import shutil
import subprocess
import sys
import tarfile
import tempfile

UPSTREAM_URL = "https://github.com/QuantumNous/new-api.git"
IDENTITY = {
    "GIT_AUTHOR_NAME": "TauAPI Maintainer",
    "GIT_AUTHOR_EMAIL": "tauapi-maintainer@localhost",
    "GIT_COMMITTER_NAME": "TauAPI Maintainer",
    "GIT_COMMITTER_EMAIL": "tauapi-maintainer@localhost",
}

# (upstream path, destination path). A trailing "/" means a directory prefix.
FRONTEND_MAP = [
    ("web/", ""),
    ("LICENSE", "LICENSE"),
    ("NOTICE", "NOTICE"),
    ("THIRD-PARTY-LICENSES.md", "THIRD-PARTY-LICENSES.md"),
    ("VERSION", "VERSION"),
    ("AGENTS.md", "UPSTREAM_ROOT_AGENTS.md"),
    ("CLAUDE.md", "CLAUDE.md"),
    (".gitattributes", ".gitattributes"),
    (".agents/", ".agents/"),
    ("pkg/billingexpr/testdata/frontend_simulation.json",
     "testdata/contracts/frontend_simulation.json"),
]
BACKEND_EXCLUDE_PREFIXES = ["web/", "electron/"]
CONTRACT_FIXTURES = ["pkg/billingexpr/testdata/frontend_simulation.json"]


def git(repo, *args, env=None, input_bytes=None, check=True):
    full_env = dict(os.environ)
    full_env.update(IDENTITY)
    if env:
        full_env.update(env)
    res = subprocess.run(["git", "-C", repo, *args], env=full_env, input=input_bytes,
                         capture_output=True)
    if check and res.returncode != 0:
        sys.stderr.write(res.stderr.decode(errors="replace"))
        raise SystemExit(4)
    return res.stdout.decode().strip()


def map_path(kind, path):
    if kind == "backend":
        if any(path.startswith(p) for p in BACKEND_EXCLUDE_PREFIXES):
            return None
        return path
    for src, dst in FRONTEND_MAP:
        if src.endswith("/"):
            if path.startswith(src):
                return dst + path[len(src):]
        elif path == src:
            return dst
    return None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--upstream", required=True)
    ap.add_argument("--sha", required=True)
    ap.add_argument("--kind", choices=["frontend", "backend"], required=True)
    ap.add_argument("--repo", required=True)
    ap.add_argument("--init-main", action="store_true")
    ap.add_argument("--ref", default="vendor/upstream", help="import branch name")
    a = ap.parse_args()

    if len(a.sha) != 40:
        print("full 40-char SHA required", file=sys.stderr)
        return 2
    if subprocess.run(["git", "-C", a.upstream, "cat-file", "-e", a.sha + "^{commit}"]).returncode:
        print(f"upstream commit {a.sha} not present in {a.upstream}", file=sys.stderr)
        return 3
    tree = git(a.upstream, "rev-parse", a.sha + "^{tree}")
    version = git(a.upstream, "show", f"{a.sha}:VERSION", check=False)

    if subprocess.run(["git", "-C", a.repo, "rev-parse", "--git-dir"], capture_output=True).returncode:
        os.makedirs(a.repo, exist_ok=True)
        git(a.repo, "init", "-q", "--initial-branch=main")
        git(a.repo, "config", "user.name", IDENTITY["GIT_AUTHOR_NAME"])
        git(a.repo, "config", "user.email", IDENTITY["GIT_AUTHOR_EMAIL"])

    with tempfile.TemporaryDirectory(prefix="tauapi-import-") as tmp:
        raw = os.path.join(tmp, "raw")
        snap = os.path.join(tmp, "snap")
        os.makedirs(raw)
        os.makedirs(snap)
        tar_path = os.path.join(tmp, "src.tar")
        with open(tar_path, "wb") as fh:
            subprocess.run(["git", "-C", a.upstream, "archive", "--format=tar", a.sha],
                           stdout=fh, check=True)
        mapped = []
        with tarfile.open(tar_path) as tf:
            for m in tf.getmembers():
                if not (m.isfile() or m.issym()):
                    continue
                if m.name.startswith("/") or ".." in m.name.split("/"):
                    print(f"refusing unsafe path {m.name}", file=sys.stderr)
                    return 4
                dst = map_path(a.kind, m.name)
                if dst is None:
                    continue
                out = os.path.join(snap, dst)
                os.makedirs(os.path.dirname(out), exist_ok=True)
                if m.issym():
                    os.symlink(m.linkname, out)
                else:
                    with tf.extractfile(m) as src, open(out, "wb") as fo:
                        shutil.copyfileobj(src, fo)
                    os.chmod(out, 0o755 if m.mode & 0o111 else 0o644)
                mapped.append((m.name, dst))

        fixtures = {}
        for fx in CONTRACT_FIXTURES:
            data = subprocess.run(["git", "-C", a.upstream, "show", f"{a.sha}:{fx}"],
                                  capture_output=True, check=True).stdout
            fixtures[fx] = {
                "sha256": hashlib.sha256(data).hexdigest(),
                "frontend_path": map_path("frontend", fx),
                "backend_path": fx,
            }
        meta = {
            "upstream_repository": UPSTREAM_URL,
            "upstream_commit": a.sha,
            "upstream_tree": tree,
            "upstream_version": version,
            "split_kind": a.kind,
            "mapping": (FRONTEND_MAP if a.kind == "frontend"
                        else [["*", "*"]] + [[p, None] for p in BACKEND_EXCLUDE_PREFIXES]),
            "mapped_file_count": len(mapped),
            "contract_fixtures": fixtures,
            "import_tool": "tauapi-ops/scripts/import-upstream.py",
        }
        with open(os.path.join(snap, "UPSTREAM.json"), "w") as fo:
            json.dump(meta, fo, indent=2, sort_keys=True)
            fo.write("\n")

        index = os.path.join(tmp, "index")
        env = {"GIT_INDEX_FILE": index, "GIT_WORK_TREE": snap}
        git(a.repo, "add", "-A", "-f", ".", env=env)
        new_tree = git(a.repo, "write-tree", env=env)

    ref = "refs/heads/" + a.ref
    parent = git(a.repo, "rev-parse", "-q", "--verify", ref, check=False)
    if parent and git(a.repo, "rev-parse", parent + "^{tree}") == new_tree:
        print(f"unchanged {a.kind} {a.ref}={parent}")
        return 0
    msg = (f"Import upstream {a.sha[:12]} ({a.kind} split)\n\n"
           f"Upstream: {UPSTREAM_URL}\nUpstream-Commit: {a.sha}\nUpstream-Tree: {tree}\n"
           f"Upstream-Version: {version}\nSplit: {a.kind}\n")
    args = ["commit-tree", new_tree, "-m", msg]
    if parent:
        args[2:2] = ["-p", parent]
    commit = git(a.repo, *args)
    git(a.repo, "update-ref", ref, commit, parent or "0" * 40)
    tag = f"upstream/{'fe' if a.kind == 'frontend' else 'be'}-{a.sha[:12]}"
    if not git(a.repo, "tag", "-l", tag):
        git(a.repo, "tag", "-a", tag, commit, "-m", f"Upstream import {a.sha}")
    if a.init_main and not git(a.repo, "rev-parse", "-q", "--verify", "refs/heads/main", check=False):
        git(a.repo, "update-ref", "refs/heads/main", commit)
        git(a.repo, "symbolic-ref", "HEAD", "refs/heads/main")
        git(a.repo, "reset", "-q", "--hard", "main")
    print(f"imported {a.kind} {a.ref}={commit} files={len(mapped)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
