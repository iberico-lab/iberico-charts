# Troubleshooting

> **In one line:** find your symptom or error message below, then apply the fix
> next to it.

**Tip:** press `Ctrl+F` (or `Cmd+F`) and paste a word from your error.

---

## First, look around

```bash
helm template my-app ./charts/app -f values.yaml   # does it render? errors show here
helm get notes my-app                              # how to reach the app
kubectl get pods -l app.kubernetes.io/instance=my-app
kubectl describe pod <pod>                         # "Events" at the bottom explain most problems
kubectl logs <pod> --previous                      # logs from the last crash
```

---

## Errors when rendering or installing

These come from the chart and stop **before** anything is created.

| Error says… | What it means | Fix |
|-------------|---------------|-----|
| `additional properties 'xyz' not allowed` | Typo or misplaced setting | Check the spelling and the level it sits at. See [Values Reference](values-reference.md) |
| `value must be one of …` | A setting only accepts certain words | Use one of the listed values (they're case-sensitive) |
| `invalid name "…"` | The name has characters Kubernetes forbids | Use lowercase letters, digits and `-` only |
| `workload.image.tag was read as the number …` | Unquoted tag like `1.10` | Quote it: `tag: "1.10"` |
| `container name "…" is already used` | Two containers share a name | Rename the sidecar or init container |
| `type=exec requires … command` | `exec` probe without a command | Add `command: [...]` to that probe |
| `persistence "…" is ReadWriteOnce, so only one pod can use it` | Several pods, one disk | `replicas: 1`, a `ReadWriteMany` storage class, or `workload.type: StatefulSet` |
| `minAvailable … must be lower than …` | The disruption budget would block every node drain | Lower `minAvailable` or add replicas |
| `minReplicas … must not be greater than maxReplicas` | Autoscaling range is upside down | Swap the numbers |
| `… needs workload.resources.requests.cpu` | Autoscaling has nothing to measure against | Set `workload.resources.requests.cpu` (and memory if you target it) |
| `type "public" requires a host` | Public ingress without a hostname | Add `host: app.example.com` |
| `… which entry … already creates` | Two ingresses of the same type | Keep one per type |
| `serviceMonitor.port "…" is not a Service port name` | Prometheus would scrape a port that doesn't exist | Use one of the names listed in the error |
| `… is mapped more than once in onepassword.secrets` | Same env var or file name used twice | Rename one of them |
| `… was removed in 0.3.0` / `… was renamed to serviceName` | Your values use a 0.2.x setting | The message names the new key. See [Upgrading](upgrading.md) |
| `… this is the Tailscale machine name only` | A full domain in an `internal` ingress `host` | `host: store`, and the tailnet in `ingress.tailnetDomain` |
| `… is not a valid Tailscale machine name` | Uppercase, `_` or too long | Up to 63 lowercase letters, numbers and `-` |
| `workload.configFiles: … must be a full file path` / `invalid propertyName` | A config file path without a leading `/` | Write the full path: `/etc/app/config.yaml` |
| `maxUnavailable and maxSurge can't both be 0` | No pod could ever be replaced | Set `workload.strategy.rollingUpdate.maxSurge: 1` |
| `workload.shutdownDelaySeconds (…) must be lower than workload.terminationGracePeriodSeconds` | The pod would be killed while it waits | Lower the delay or raise the grace period |
| `securityPreset restricted: … can't be …` / `may only contain NET_BIND_SERVICE` | A setting breaks the restricted standard | Remove that setting, or drop `securityPreset` |
| `chart requires kubeVersion: >=1.30.0-0 which is incompatible with Kubernetes v1.2x` | The cluster is older than 1.30 | Upgrade the cluster. Older versions no longer get security fixes |
| `field is immutable` (on upgrade) | A locked field changed | See [Upgrading](upgrading.md) |
| `updates to statefulset spec for fields other than ... are forbidden` | StatefulSet installed with 0.2.x and has disks | One-time `--cascade=orphan` step in [Upgrading](upgrading.md#statefulsets-with-disks-one-time-step) |

---

## The pod won't start

| You see… | Usually means | Fix |
|----------|---------------|-----|
| `ImagePullBackOff` / `ErrImagePull` | Wrong image name/tag, or a private registry | Check `workload.image`; for private registries set `imagePullSecrets` |
| `CrashLoopBackOff` | The app keeps exiting | `kubectl logs <pod> --previous`. Often a missing setting or secret |
| `OOMKilled` (in `kubectl describe pod`) | The app used more memory than its limit (`512Mi` by default) | Raise `workload.resources.limits.memory` |
| Restarts every minute or so, logs look fine | Liveness probe fails | Fix `path`/`port`, or use `type: tcp`. See [Health checks](probes.md) |
| `Running` but `0/1 READY` | Readiness probe fails | Same as above: check the probe matches your app |
| `Pending` with `unbound PersistentVolumeClaims` | Disk can't be created | Check `storageClassName` exists (`kubectl get storageclass`) and supports the access mode |
| `ContainerCreating` with `Multi-Attach error` | Disk already used by another node | One pod per `ReadWriteOnce` disk; see [Persistence](persistence.md) |
| `CreateContainerConfigError` with `runAsNonRoot` | Image runs as root but you enabled strict security | Set `runAsUser`, or drop the strict block. See [Security](security.md) |
| `CreateContainerConfigError` with `secret … not found` | The 1Password secret hasn't synced yet | See "Secrets" below |
| `Pending` with `didn't match pod topology spread` | Strict spread, not enough nodes/zones | Use `whenUnsatisfiable: ScheduleAnyway`. See [Availability](availability.md) |

---

## Secrets (1Password)

```bash
kubectl get externalsecrets               # STATUS should be SecretSynced
kubectl describe externalsecret <name>    # the reason if it isn't
```

| Status / message | Fix |
|------------------|-----|
| `SecretSyncedError` … `item not found` | The `secretKey` doesn't match a 1Password item name |
| … `property not found` | The field name (right side of `mappings`) doesn't exist on that item |
| `ClusterSecretStore … not found` | Set `clusterSecretStoreRef` to the store your cluster has |
| No ExternalSecret at all | Check `external-secrets.enabled: true` and that you listed `secrets` |
| Changed in 1Password, app still has the old value | Env vars are read at start. Restart the pod, or turn on `workload.reloadOnSecretChange` |

---

## Can't reach the app

| Symptom | Fix |
|---------|-----|
| Works with port-forward, not from other apps | Use the address from `helm get notes`. Check `workload.applicationPort` is the port the app really listens on |
| Browser shows a certificate warning | The ingress uses `letsencrypt-staging` by default. Set `certManagerIssuer` to your production issuer |
| Public URL gives 404 | DNS for `host` must point at your Traefik load balancer |
| Tailscale URL doesn't resolve | Check the device is on the tailnet, and the ingress exists: `kubectl get ingress` |
| Login loop on `public-protected` | The `network-sso` Traefik middleware must exist and work |

---

## Ingress gives 502/504, or Prometheus can't scrape

With `networkPolicy.enabled: true`, only the listed namespaces get in. Add the
ingress controller's (or Prometheus's) namespace to `networkPolicy.allowNamespaces`.

---

## Still stuck?

Render with `--debug` to see the generated YAML, even when it's invalid:

```bash
helm template my-app ./charts/app -f values.yaml --debug
```
