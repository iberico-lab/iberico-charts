#!/usr/bin/env bash
# End-to-end test: install every hack/e2e/*.yaml scenario on a real cluster,
# wait for it to be ready, run `helm test`, upgrade, test again, uninstall.
#
#   KUBE_CONTEXT=<context> hack/e2e.sh      # defaults to the current context
#
# Use a throwaway cluster (kind, minikube, k3d). Everything is created in the
# namespace below and deleted at the end.
set -euo pipefail
cd "$(dirname "$0")/.."

NS=${E2E_NAMESPACE:-iberico-e2e}
CTX_ARGS=()
[ -n "${KUBE_CONTEXT:-}" ] && CTX_ARGS=(--kube-context "$KUBE_CONTEXT")
KCTX_ARGS=()
[ -n "${KUBE_CONTEXT:-}" ] && KCTX_ARGS=(--context "$KUBE_CONTEXT")

helm() { command helm "${CTX_ARGS[@]}" "$@"; }
kubectl() { command kubectl "${KCTX_ARGS[@]}" "$@"; }

cleanup() {
  echo "==> cleaning up namespace $NS"
  for f in hack/e2e/*.yaml; do helm uninstall "$(basename "$f" .yaml)" -n "$NS" --wait >/dev/null 2>&1 || true; done
  kubectl delete namespace "$NS" --wait=false >/dev/null 2>&1 || true
}
trap cleanup EXIT

dump() {
  echo "!! $1 failed; cluster state:"
  kubectl get all,pvc,events -n "$NS" || true
}

for f in hack/e2e/*.yaml; do
  name=$(basename "$f" .yaml)
  echo "==> [$name] install"
  helm install "$name" charts/app -n "$NS" --create-namespace -f "$f" --wait --timeout 5m || { dump "$name install"; exit 1; }
  echo "==> [$name] helm test"
  helm test "$name" -n "$NS" --timeout 3m || { dump "$name test"; exit 1; }
  echo "==> [$name] upgrade"
  helm upgrade "$name" charts/app -n "$NS" -f "$f" --set global.version=e2e-upgrade --wait --timeout 5m || { dump "$name upgrade"; exit 1; }
  helm test "$name" -n "$NS" --timeout 3m || { dump "$name test after upgrade"; exit 1; }
  echo "==> [$name] OK"
done
echo "==> all scenarios passed"
