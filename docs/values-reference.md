# Values Reference

> **In one line:** every setting in `charts/app/values.yaml` on one page, so you
> can look it up quickly.

**How to use this page:** press `Ctrl+F` (or `Cmd+F`) and type the setting name.
For explanations and examples, follow the  link in each section.

---

## Top level

| Setting | Default | What it does |
|---------|---------|--------------|
| `global.name` | `""` | Base name for everything (`""` = release name) ([docs](architecture.md)) |
| `global.fullnameOverride` | `""` | Replaces the full name |
| `global.nameOverride` | `""` | Changes the name label only |
| `global.version` | `""` | Version label for every resource (`""` = image tag) |
| `workload` | see below | Your app ([docs](workload.md)) |
| `service` | see below | Address inside the cluster ([docs](service.md)) |
| `persistence` | `[]` | Disks the chart creates ([docs](persistence.md)) |
| `serviceAccount` | see below | Kubernetes identity for the pods |
| `metrics.serviceMonitor` | `{enabled: false, path: /metrics, interval: 30s}` | Prometheus scraping ([docs](metrics.md)) |
| `autoscaling` | `{enabled: false, minReplicas: 2, maxReplicas: 5, targetCPUUtilizationPercentage: 80}` | Scale with CPU/memory ([docs](availability.md)) |
| `podDisruptionBudget` | `{enabled: false, minAvailable: null, maxUnavailable: 1}` | Pods allowed down during maintenance ([docs](availability.md)) |
| `podSecurityContext` | `seccompProfile: RuntimeDefault` | Security settings for the pod ([docs](security.md)) |
| `securityContext` | `allowPrivilegeEscalation: false` | Security settings for the main container ([docs](security.md)) |
| `topologySpread` | `{enabled: false, topologyKey: kubernetes.io/hostname, maxSkew: 1, whenUnsatisfiable: ScheduleAnyway}` | Spread pods across nodes/zones ([docs](availability.md)) |
| `topologySpreadConstraints` | `[]` | Raw spread rules, copied as-is |
| `priorityClassName` | `""` | PriorityClass for the pods |
| `nodeSelector` | `{}` | Only run on nodes with these labels |
| `affinity` | `{}` | Rules for where pods should (or shouldn't) run |
| `tolerations` | `[]` | Allow running on "tainted" nodes |
| `imagePullSecrets` | `[]` | Login details for private image registries |
| `external-secrets` | `{enabled: false}` | Secrets from 1Password ([docs](external-secrets.md)) |
| `ingress` | `{enabled: false}` | URLs ([docs](ingress.md)) |
| `extraManifests` | `[]` | Extra objects to install ([docs](extra-manifests.md)) |

---

## `workload` ([docs](workload.md))

| Setting | Default | What it does |
|---------|---------|--------------|
| `workload.enabled` | `true` | Turn the workload on/off |
| `workload.type` | `Deployment` | `Deployment` or `StatefulSet` |
| `workload.image.repository` | `nginx` | Image to run |
| `workload.image.tag` | `1.25` | Image version |
| `workload.image.pullPolicy` | `IfNotPresent` | When to download the image again |
| `workload.replicas` | `2` | Number of copies |
| `workload.applicationPort` | `80` | Port the app listens on |
| `workload.ports` | `[]` | Named ports (`name`/`port`/`protocol`). Replaces `applicationPort` |
| `workload.command` | `[]` | Start command (`[]` = image default) |
| `workload.args` | `[]` | Start arguments (`[]` = image default) |
| `workload.environment` | `{}` | Plain settings as `KEY: value` |
| `workload.extraEnv` | `[]` | Raw env entries (supports `valueFrom`) |
| `workload.extraEnvFrom` | `[]` | Raw `envFrom` entries |
| `workload.volumes` | `[]` | Mount existing things ([docs](volumes.md)) |
| `workload.lifecycle` | `{}` | `postStart` / `preStop` hooks |
| `workload.extraContainers` | `[]` | Sidecars ([docs](sidecars.md)) |
| `workload.extraInitContainers` | `[]` | Init containers ([docs](sidecars.md)) |
| `workload.resources` | requests `300m`/`512Mi`, limits `1000m`/`800Mi` | CPU and memory |
| `workload.livenessProbe` | HTTP `/` | Restart check ([docs](probes.md)) |
| `workload.readinessProbe` | HTTP `/` | Traffic check ([docs](probes.md)) |
| `workload.startupProbe` | HTTP `/` | Startup check ([docs](probes.md)) |
| `workload.annotations` | `{}` | Annotations on the Deployment/StatefulSet |
| `workload.reloadOnSecretChange` | `false` | Restart pods when 1Password secrets change (needs Reloader) |
| `workload.pod.annotations` | `{}` | Annotations on each pod |
| `workload.pod.labels` | `{}` | Extra labels on each pod |
| `workload.strategy` | `RollingUpdate`, `maxUnavailable: 1`, `maxSurge: 1` | Deployment update style |
| `workload.terminationGracePeriodSeconds` | `30` | Seconds the app gets to shut down cleanly |

### StatefulSet only ([docs](statefulset.md))

| Setting | Default | What it does |
|---------|---------|--------------|
| `workload.serviceName` | `""` | Headless Service name (`""` = `<app>-cluster`) |
| `workload.updateStrategy` | `{type: RollingUpdate}` | How pods are updated |
| `workload.podManagementPolicy` | `""` | `OrderedReady` (one pod at a time) or `Parallel` (all at once) |
| `service.headless.port` | `null` | Headless Service port (`null` = `applicationPort`) |
| `service.headless.targetPort` | `null` | Headless Service target port (`null` = `applicationPort`) |
| `service.headless.ports` | `[]` | Several ports |
| `service.headless.annotations` | `{}` | Headless Service annotations |

---

## Probes ([docs](probes.md))

Defaults are shown as **liveness / readiness / startup**.

| Setting | Default |
|---------|---------|
| `enabled` | `true` / `true` / `true` |
| `type` | `http` / `http` / `http` |
| `path` | `/` / `/` / `/` |
| `port` | `null` (= `applicationPort`) |
| `custom` | `false` |
| `spec` | `{}` |
| `initialDelaySeconds` | `0` / `0` / `5` |
| `periodSeconds` | `10` / `5` / `5` |
| `timeoutSeconds` | `1` / `1` / `3` |
| `failureThreshold` | `3` / `3` / `30` |
| `successThreshold` | `1` / `1` / `1` |

---

## `service` ([docs](service.md))

| Setting | Default | What it does |
|---------|---------|--------------|
| `service.enabled` | `true` | Create the Service |
| `service.type` | `ClusterIP` | `ClusterIP`, `NodePort` or `LoadBalancer` |
| `service.port` | `80` | Port others connect to |
| `service.targetPort` | `null` | Port on your container (`null` = `workload.applicationPort`) |
| `service.portName` | `http` | Name of the single port (max 15 characters) |
| `service.annotations` | `{}` | Extra annotations |
| `service.ports` | `[]` | Several ports (replaces `port`/`targetPort`) |

---

## `serviceAccount`

| Setting | Default | What it does |
|---------|---------|--------------|
| `serviceAccount.create` | `false` | Create a ServiceAccount |
| `serviceAccount.automount` | `false` | Mount a Kubernetes API token into the pods |
| `serviceAccount.name` | `""` | Name (`""` = app name) |
| `serviceAccount.annotations` | `{}` | Annotations |

---

## `persistence`,  `external-secrets`,  `ingress`

Each one has its full settings table on its own page:
[Persistence](persistence.md) · [External Secrets](external-secrets.md) · [Ingress](ingress.md)
