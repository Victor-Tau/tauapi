# API-only backend. The dashboard frontend is a separate repository with its
# own build and release; nothing here builds or embeds web assets.
DEV_COMPOSE_FILE = docker-compose.dev.yml
DEV_POSTGRES_SERVICE = postgres
DEV_API_SERVICE = new-api
DEV_POSTGRES_DB = new-api
DEV_POSTGRES_USER = root
DEV_SQLITE_PATH ?= one-api.db
# JavaScript task plugin tooling (moved from the former web/package.json).
OXLINT_VERSION ?= 1.74.0
OXFMT_VERSION ?= 0.72.0
PLUGIN_TOOL ?= bunx
TEST_MODULE ?= .
TEST_PACKAGES ?=

.PHONY: all build start-api dev-api dev-api-rebuild reset-setup test lint-plugins format-plugins format-plugins-check

all: build

build:
	@echo "Building API-only backend..."
	@GOWORK=off go build -ldflags "-s -w -X 'github.com/QuantumNous/new-api/common.Version=$$(cat VERSION)'" -o new-api .

start-api:
	@echo "Starting api dev server..."
	@GOWORK=off go run . &

dev-api:
	@echo "Starting api services (docker)..."
	@docker compose -f $(DEV_COMPOSE_FILE) up -d

dev-api-rebuild:
	@echo "Rebuilding and starting api service (docker)..."
	@docker compose -f $(DEV_COMPOSE_FILE) up -d --build $(DEV_API_SERVICE)

test:
	@case "$(TEST_MODULE)" in .|relaykit|tokenkit) ;; *) echo 'Select one changed module with TEST_MODULE.' >&2; exit 2 ;; esac
	@test -n "$(TEST_PACKAGES)" || { echo 'Set TEST_PACKAGES to explicit new or modified packages.' >&2; exit 2; }
	@for package in $(TEST_PACKAGES); do case "$$package" in *...*) echo 'Recursive test suites are prohibited.' >&2; exit 2 ;; esac; case "$$package" in .|./*) ;; *) echo 'Use explicit local package paths.' >&2; exit 2 ;; esac; done
	@cd "$(TEST_MODULE)" && GOWORK=off go test $(TEST_PACKAGES)

lint-plugins:
	@cd plugins && $(PLUGIN_TOOL) oxlint@$(OXLINT_VERSION) -c .oxlintrc.json .

format-plugins:
	@cd plugins && $(PLUGIN_TOOL) oxfmt@$(OXFMT_VERSION) -c .oxfmtrc.json --write .

format-plugins-check:
	@cd plugins && $(PLUGIN_TOOL) oxfmt@$(OXFMT_VERSION) -c .oxfmtrc.json --check .

reset-setup:
	@echo "Resetting local setup wizard state..."
	@if docker compose -f $(DEV_COMPOSE_FILE) ps --services --status running | grep -qx "$(DEV_POSTGRES_SERVICE)"; then \
		echo "Detected running docker dev PostgreSQL. Removing setup record and root users..."; \
		docker compose -f $(DEV_COMPOSE_FILE) exec -T $(DEV_POSTGRES_SERVICE) \
			psql -U $(DEV_POSTGRES_USER) -d $(DEV_POSTGRES_DB) \
			-c 'DELETE FROM setups;' \
			-c 'DELETE FROM users WHERE role = 100;' \
			-c "DELETE FROM options WHERE key IN ('SelfUseModeEnabled', 'DemoSiteEnabled');"; \
		echo "Restarting docker dev api so setup status is recalculated..."; \
		docker compose -f $(DEV_COMPOSE_FILE) restart $(DEV_API_SERVICE); \
	elif db_path="$${SQLITE_PATH:-$(DEV_SQLITE_PATH)}"; db_path="$${db_path%%\?*}"; [ -f "$$db_path" ]; then \
		db_path="$${SQLITE_PATH:-$(DEV_SQLITE_PATH)}"; \
		db_path="$${db_path%%\?*}"; \
		echo "Detected local SQLite database: $$db_path"; \
		sqlite3 "$$db_path" \
			"DELETE FROM setups; DELETE FROM users WHERE role = 100; DELETE FROM options WHERE key IN ('SelfUseModeEnabled', 'DemoSiteEnabled');"; \
		echo "SQLite setup state reset. Restart the local api process before testing the setup wizard."; \
	else \
		echo "No running docker dev PostgreSQL or local SQLite database found."; \
		echo "Start the dev stack with 'make dev-api', or set SQLITE_PATH/DEV_SQLITE_PATH to your local SQLite database."; \
		exit 1; \
	fi
