#!/usr/bin/env bash
# End-to-end test: install every hack/e2e/*.yaml scenario on a real cluster,
# wait for it to be ready, run `helm test`, upgrade, test again, uninstall.
#
#   KUBE_CONTEXT=<context> hack/e2e.sh      # defaults to the current context
#
# Use a throwaway cluster (kind, minikube, k3d). Scenarios run in the namespace
# below; the add-ons they need (External Secrets Operator with a fake store
# standing in for 1Password, Prometheus Operator CRDs) go in $NS-addons. Both
# namespaces are deleted at the end; the add-on CRDs stay.
#
# A scenario can ship hack/e2e/<name>.check.sh: it runs after install and
# after upgrade, to check that values really reached the pod.
set -euo pipefail
cd "$(dirname "$0")/.."

NS=${E2E_NAMESPACE:-iberico-e2e}
ADDONS_NS="$NS-addons"
ESO_VERSION=2.14.0             # https://charts.external-secrets.io
PROM_CRDS_VERSION=32.0.2       # prometheus-community/prometheus-operator-crds
CTX_ARGS=()
[ -n "${KUBE_CONTEXT:-}" ] && CTX_ARGS=(--kube-context "$KUBE_CONTEXT")
KCTX_ARGS=()
[ -n "${KUBE_CONTEXT:-}" ] && KCTX_ARGS=(--context "$KUBE_CONTEXT")

helm() { command helm "${CTX_ARGS[@]}" "$@"; }
kubectl() { command kubectl "${KCTX_ARGS[@]}" "$@"; }

cleanup() {
  echo "==> cleaning up namespaces $NS and $ADDONS_NS"
  for f in hack/e2e/*.yaml; do helm uninstall "$(basename "$f" .yaml)" -n "$NS" --wait >/dev/null 2>&1 || true; done
  kubectl delete clustersecretstore e2e-fake --ignore-not-found >/dev/null 2>&1 || true
  helm uninstall external-secrets -n "$ADDONS_NS" >/dev/null 2>&1 || true
  helm uninstall prometheus-operator-crds -n "$ADDONS_NS" >/dev/null 2>&1 || true
  kubectl delete namespace "$NS" "$ADDONS_NS" --wait=false >/dev/null 2>&1 || true
}
trap cleanup EXIT

dump() {
  echo "!! $1 failed; cluster state:"
  kubectl get all,pvc,ingress,externalsecrets,events -n "$NS" || true
}

check() {  # run hack/e2e/<name>.check.sh if there is one
  local script="hack/e2e/$1.check.sh"
  [ -f "$script" ] || return 0
  echo "==> [$1] checks"
  ( source "$script" )
}

# Charts are fetched by URL, so your own `helm repo` list is left alone.
echo "==> add-ons: External Secrets Operator $ESO_VERSION, Prometheus Operator CRDs $PROM_CRDS_VERSION"
HELM_REPOSITORY_CONFIG=/dev/null helm upgrade --install prometheus-operator-crds prometheus-operator-crds \
  --repo https://prometheus-community.github.io/helm-charts --version "$PROM_CRDS_VERSION" \
  -n "$ADDONS_NS" --create-namespace --wait --timeout 5m
HELM_REPOSITORY_CONFIG=/dev/null helm upgrade --install external-secrets external-secrets \
  --repo https://charts.external-secrets.io --version "$ESO_VERSION" \
  -n "$ADDONS_NS" --create-namespace --set installCRDs=true --wait --timeout 5m
# The webhook must be serving before a ClusterSecretStore can be created.
for _ in $(seq 30); do kubectl apply -f hack/e2e/setup/fake-secret-store.yaml >/dev/null 2>&1 && break; sleep 5; done
kubectl apply -f hack/e2e/setup/fake-secret-store.yaml

for f in hack/e2e/*.yaml; do
  name=$(basename "$f" .yaml)
  echo "==> [$name] install"
  helm install "$name" charts/app -n "$NS" --create-namespace -f "$f" --wait --timeout 5m || { dump "$name install"; exit 1; }
  echo "==> [$name] helm test"
  helm test "$name" -n "$NS" --timeout 3m || { dump "$name test"; exit 1; }
  check "$name" || { dump "$name checks"; exit 1; }
  echo "==> [$name] upgrade"
  helm upgrade "$name" charts/app -n "$NS" -f "$f" --set global.version=e2e-upgrade --wait --timeout 5m || { dump "$name upgrade"; exit 1; }
  helm test "$name" -n "$NS" --timeout 3m || { dump "$name test after upgrade"; exit 1; }
  check "$name" || { dump "$name checks after upgrade"; exit 1; }
  echo "==> [$name] OK"
done
echo "==> all scenarios passed"
