#!/usr/bin/env bash
# Runs after `integrations` is installed: did each value reach the pod?
# Called by hack/e2e.sh with $NS set and kubectl wrapped for the context.
set -euo pipefail
# A running app pod that isn't shutting down. `kubectl exec deploy/...` can pick
# an old pod that is still terminating right after an upgrade.
live_pod() {
  kubectl get pod -n "$NS" -l app.kubernetes.io/name=integrations,app.kubernetes.io/instance=integrations \
    -o go-template='{{range .items}}{{if and (not .metadata.deletionTimestamp) (eq .status.phase "Running")}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}' | head -n1
}
pod_exec() { kubectl exec -n "$NS" "$(live_pod)" -c integrations -- "$@"; }
expect() {  # expect <what> <want> <got>
  if [ "$2" != "$3" ]; then echo "!! $1: want '$2', got '$3'"; exit 1; fi
  echo "   ok: $1"
}

expect "1Password env var (via ExternalSecret)" "s3cret-from-store" "$(pod_exec printenv DB_PASSWORD)"
expect "1Password file (via ExternalSecret)" "CERT-FROM-STORE" "$(pod_exec cat /etc/secrets/onepassword/tls.crt)"
expect "configFiles file" "e2e-config-file" "$(pod_exec cat /usr/share/nginx/html/index.html)"
expect "configFiles leaves the rest of the folder" "yes" "$(pod_exec sh -c 'test -f /usr/share/nginx/html/50x.html && echo yes')"
expect "Tailscale machine name (first tls host)" "integrations" \
  "$(kubectl get ingress integrations-internal -n "$NS" -o jsonpath='{.spec.tls[0].hosts[0]}')"
expect "public ingress host" "e2e.example.com" \
  "$(kubectl get ingress integrations-public -n "$NS" -o jsonpath='{.spec.rules[0].host}')"
expect "HTTPRoute accepted by the API" "route.example.com" \
  "$(kubectl get httproute integrations -n "$NS" -o jsonpath='{.spec.hostnames[0]}')"
expect "ServiceMonitor accepted by the API" "integrations" \
  "$(kubectl get servicemonitor integrations -n "$NS" -o jsonpath='{.metadata.name}')"

# Editing a config file must roll the pods: subPath mounts never update in
# place, so without the checksum annotation the old contents would stay.
helm upgrade integrations charts/app -n "$NS" --reuse-values --wait --timeout 5m \
  --set-json 'workload.configFiles={"/usr/share/nginx/html/index.html":"e2e-config-file-v2"}' >/dev/null
kubectl rollout status deploy/integrations -n "$NS" --timeout 5m >/dev/null
expect "edited config file reaches the new pods" "e2e-config-file-v2" "$(pod_exec cat /usr/share/nginx/html/index.html)"
