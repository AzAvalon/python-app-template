.DEFAULT_GOAL := help
.PHONY: help install lint test coverage run chart-lint docker clean ci-setup tests-with-coverage ci-post-run

## Local development

help: ## Show this help
	@grep -hE '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | \
	  awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

install: ## Create .venv with the app and the dev dependencies
	uv sync --locked

lint: ## Run the pre-commit hooks on every file
	prek run --all-files

test: ## Run the tests
	uv run --locked pytest

coverage: ## Run the tests with a coverage report in the terminal
	uv run --locked pytest --cov --cov-report=term-missing

run: ## Start the app on port 8000
	uv run --locked app

chart-lint: ## Lint the chart with chart-testing (ct.yaml, lintconf.yaml), in docker
	docker run --rm --user $$(id -u):$$(id -g) -e HOME=/tmp -v "$$PWD":/w -w /w \
	  quay.io/helmpack/chart-testing:v3.14.0 \
	  sh -c 'git config --global --add safe.directory /w && ct lint --config ct.yaml'

docker: ## Build the image for the local platform
	DOCKER_PLATFORMS=linux/$$(docker version -f '{{.Server.Arch}}') \
	  docker buildx bake -f dockerfiles/docker-bake.hcl --load

clean: ## Remove the virtualenv, caches and test reports
	rm -rf .venv .pytest_cache .ruff_cache .coverage coverage.info junit.xml dist chart/charts
	find . -type d -name __pycache__ -prune -exec rm -rf {} +

## CI targets, called by AzAvalon/workflows _tests_app.yml

ci-setup: install

# _tests_app.yml uploads coverage.info (lcov) and junit.xml
tests-with-coverage:
	uv run --locked pytest --cov --cov-report=lcov:coverage.info --junitxml=junit.xml

ci-post-run:
	@echo "Nothing to clean up"
