COMPOSE = docker compose --env-file .env.demo -f compose.demo.yaml
PYTHON ?= python3

.PHONY: test test-unit test-integration test-selenium

test: test-unit test-integration test-selenium

test-unit:
	$(PYTHON) -m unittest tools.test_verify_release_checks
	$(COMPOSE) build bootstrap
	$(COMPOSE) run --rm --no-deps -e FLEETOPS_ENV=test -e FLEETOPS_DATABASE_NAME=fleetops_test_001 bootstrap python -m pytest tests/unit -q -p no:cacheprovider
	cd apps/web && npm ci --no-audit --no-fund && npm run lint && npm run typecheck && npm test -- --run && npm run build

test-integration:
	$(COMPOSE) up -d --build --wait
	$(COMPOSE) run --rm --no-deps -e FLEETOPS_DEMO_BASE_URL=http://api:8000 bootstrap python -m pytest tests/integration/demo -q -p no:cacheprovider
	$(COMPOSE) run --rm --no-deps -e FLEETOPS_ENV=test -e FLEETOPS_DATABASE_NAME=fleetops_test_001 bootstrap python tools/bootstrap_test_database.py
	$(COMPOSE) run --rm --no-deps -e FLEETOPS_ENV=test -e FLEETOPS_DATABASE_NAME=fleetops_test_001 -e FLEETOPS_TEST_MIGRATION_BRANCH=production bootstrap alembic -x target=production@head upgrade production@head
	$(COMPOSE) run --rm --no-deps -e FLEETOPS_ENV=test -e FLEETOPS_DATABASE_NAME=fleetops_test_001 -e FLEETOPS_TEST_MIGRATION_BRANCH=production bootstrap python -m pytest tests/integration/production -q -p no:cacheprovider

test-selenium:
	$(COMPOSE) up -d --build --wait
	FLEETOPS_DEMO_BASE_URL=http://127.0.0.1:18080 $(PYTHON) -m pytest tests/selenium -q -p no:cacheprovider
