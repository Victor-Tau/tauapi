DOCS_PYTHON := $(CURDIR)/.docs-venv/bin/python
DOCS_BASE ?= HEAD
DOCS_HEAD ?= HEAD
DOCS_CHANGE ?= $(firstword $(wildcard docs/ai/changes/active/*.json))
DOCS := $(DOCS_PYTHON) docs/tools/docsctl.py
.PHONY: docs-setup docs-check docs-generate docs-test docs-audit docs-impact docs-impact-worktree docs-verify
docs-setup:
	@if command -v uv >/dev/null 2>&1; then uv venv --allow-existing --seed .docs-venv; else python3 -m venv .docs-venv; fi
	.docs-venv/bin/python -m pip install -r docs/tools/requirements.txt
docs-check:
	$(DOCS) check
docs-generate:
	$(DOCS) generate --write
docs-test:
	@test -n "$(DOCS_TEST_MODULES)" || { echo 'Set DOCS_TEST_MODULES to explicit tests for new or modified modules.' >&2; exit 2; }
	@for target in $(DOCS_TEST_MODULES); do case "$$target" in *'*'*|*'?'*|*'['*) echo 'Test wildcards and discovery are prohibited.' >&2; exit 2 ;; esac; case "$$target" in docs.tools.tests.test_*) ;; *) echo 'Select an explicit documentation test module or case.' >&2; exit 2 ;; esac; done
	$(DOCS_PYTHON) -m unittest -v $(DOCS_TEST_MODULES)
docs-audit:
	$(DOCS) audit --format json
docs-impact:
	$(DOCS) impact --base $(DOCS_BASE) --head $(DOCS_HEAD) --format json
docs-impact-worktree:
	$(DOCS) impact --base $(DOCS_BASE) --worktree --format json
docs-verify:
	$(DOCS) run-checks --base $(DOCS_BASE) --head $(DOCS_HEAD) --record $(DOCS_CHANGE) --evidence-dir .docs-reports
