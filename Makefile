# Local helpers mirroring the CI workflows in .github/workflows/.
#
# Charts are built bottom-up: library -> subcharts -> umbrella `app` chart.

CHARTS_DIR := charts
CHARTS     := helm-helpers external-secrets ingress app
EXAMPLES   := $(sort $(wildcard examples/*/values.yaml))

# Every dependency is a local file:// sibling chart, so ignore the user's
# configured Helm repos (a single broken repo would otherwise fail the build).
HELM_DEP   := HELM_REPOSITORY_CONFIG=/dev/null helm dependency update --skip-refresh

.PHONY: help deps lint test template examples schema schema-check clean

help: ## Show available targets
	@grep -E '^[a-z-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-10s %s\n", $$1, $$2}'

deps: ## Resolve file:// sub-chart dependencies for every chart
	@for c in $(CHARTS); do $(HELM_DEP) $(CHARTS_DIR)/$$c || exit 1; done

lint: deps ## helm lint every chart
	@for c in $(CHARTS); do helm lint $(CHARTS_DIR)/$$c || exit 1; done

test: deps ## Run unit tests (needs the helm-unittest plugin)
	helm unittest $(CHARTS_DIR)/app $(CHARTS_DIR)/ingress $(CHARTS_DIR)/external-secrets

template: deps ## Render the umbrella app chart with default values
	helm template app $(CHARTS_DIR)/app

examples: deps ## Render every example under examples/ against the app chart
	@for f in $(EXAMPLES); do echo "==> $$f"; helm template t $(CHARTS_DIR)/app -f $$f > /dev/null || exit 1; done

schema: ## Regenerate values.schema.json files (run after changing values)
	python3 hack/gen-values-schema.py .

schema-check: ## Fail if values.schema.json files are out of date
	python3 hack/gen-values-schema.py . && git diff --exit-code -- 'charts/*/values.schema.json'

clean: ## Remove vendored sub-chart artifacts and lock files
	rm -rf $(CHARTS_DIR)/*/charts $(CHARTS_DIR)/*/Chart.lock
