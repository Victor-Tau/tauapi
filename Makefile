DOCS_PYTHON := $(CURDIR)/.docs-venv/bin/python
DOCS_BASE ?= HEAD
DOCS_HEAD ?= HEAD
DOCS_CHANGE ?= docs/ai/changes/active/docs-system-bootstrap.json
DOCS := $(DOCS_PYTHON) scripts/docs/docsctl.py
.PHONY: docs-setup docs-check docs-generate docs-test docs-audit docs-impact docs-impact-worktree docs-verify
docs-setup:
	@if command -v uv >/dev/null 2>&1; then uv venv --allow-existing --seed .docs-venv; else python3 -m venv .docs-venv; fi
	.docs-venv/bin/python -m pip install -r scripts/docs/requirements.txt
docs-check:
	$(DOCS) check
docs-generate:
	$(DOCS) generate --write
docs-test:
	$(DOCS_PYTHON) -m unittest discover -s scripts/docs/tests -v
docs-audit:
	$(DOCS) audit --format json
docs-impact:
	$(DOCS) impact --base $(DOCS_BASE) --head $(DOCS_HEAD) --format json
docs-impact-worktree:
	$(DOCS) impact --base $(DOCS_BASE) --worktree --format json
docs-verify:
	$(DOCS) run-checks --base $(DOCS_BASE) --head $(DOCS_HEAD) --record $(DOCS_CHANGE) --evidence-dir .docs-reports
