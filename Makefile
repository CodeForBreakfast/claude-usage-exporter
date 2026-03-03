.PHONY: check lint-dashboards

check: lint-dashboards

lint-dashboards:
	@bash scripts/lint-dashboards.sh
