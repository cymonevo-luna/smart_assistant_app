.PHONY: help ci smoke-oauth-local

help: ## Show available targets
	@grep -E '^[a-zA-Z0-9_.-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}'

# Prerequisite: smart_assistant_api scripts/qa-local-up.sh must be running (localhost:8080).
smoke-oauth-local: ## Run OAuth API + Flutter smoke test against local QA API
	@test -f .env || cp .env.qa-local.example .env
	@scripts/plugin-setup-oauth-smoke-test.sh

ci: ## Run static analysis, tests, and web release build
	@scripts/ensure-flutter-test-env.sh --check-vm
	@test -f .env || cp .env.example .env
	@flutter analyze
	@flutter test
	@flutter build web --release
