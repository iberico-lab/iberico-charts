# Upgrading

> **In one line:** read this before you upgrade to a new chart version. It lists
> anything you have to do by hand.

Just shipping a new version of **your app**? You don't need this page: change
`workload.image.tag` and upgrade. See [Versions](versioning.md).

---

## 0.2.x to 0.3.0

### Names now default to the release name

If `global.name` is empty, resources are now named after the **Helm release**
(for example `helm install shop ...` gives you `shop`). Before, they were all
named `app`, so two releases in one namespace overwrote each other.

**Do you need to do anything?**

- **You set `global.name`:** no. Names don't change.
- **You didn't set `global.name`:** yes. The simplest fix is to keep the old
  name by adding this to your values file:

  ```yaml
  global:
    name: "app"
  ```

  Or let the names change: Helm creates new resources with the new names and
  deletes the old ones. That means a short outage, and **Deployment disks
  (PVCs) get new, empty volumes**, so pin `global.name` if you have data.

### Disks default to ReadWriteOnce

`persistence` entries without `accessModes` used to get `ReadWriteMany`, which
many storage types don't support (the disk stayed Pending). The default is now
`ReadWriteOnce`.

**If you have existing disks that relied on the old default**, pin it, because
Kubernetes won't let a disk's access mode change and the upgrade would fail:

```yaml
persistence:
  - name: data
    accessModes: ["ReadWriteMany"]   # keep what the disk was created with
    # ...
```

### Service forwards to applicationPort

`service.targetPort` now defaults to `workload.applicationPort` (it was `80`).
If you set `targetPort` yourself, nothing changes. If you relied on the old
value while `applicationPort` was something else, set `service.targetPort: 80`.

### Headless Service settings moved

Everything about the StatefulSet headless Service now lives in
`service.headless`, next to the normal Service. The old keys were removed; if
your values still use them, the chart stops and tells you where they went.

| Before | Now |
|--------|-----|
| `workload.service.port` / `targetPort` / `ports` / `annotations` | `service.headless.port` / `targetPort` / `ports` / `annotations` |
| `workload.serviceName` | `service.headless.name` |

```yaml
# before                        # now
workload:                       service:
  serviceName: db-cluster         headless:
  service:                          name: db-cluster
    port: 5432                      port: 5432
```

### StatefulSets with disks: one-time step

Disk templates (`volumeClaimTemplates`) now carry only stable labels. Before,
they also had the chart and version labels, so **every** upgrade of a
StatefulSet with `persistence` failed with
`updates to statefulset spec for fields other than ... are forbidden`.

Kubernetes won't let you change that part of an existing StatefulSet, so do
this once per StatefulSet that has `persistence`. Your pods and disks keep
running and keep their data:

```bash
kubectl delete statefulset <app> -n <namespace> --cascade=orphan
helm upgrade <release> ./charts/app -f values-myapp.yaml
```

Deployments, and StatefulSets without `persistence`, need nothing.

### Ingress `name` is now `serviceName`

Each entry in `ingress.ingresses` used `name` for the Service to send traffic
to. It's now `serviceName`, which says what it is. Rename the key; the chart
stops with a message if it finds the old one.

### Ingress type `public-protected` is now `public-sso`

The type was named after the implementation, not what it gives you. Rename it
in your values; the schema rejects the old value.

```yaml
ingress:
  ingresses:
    - type: "public-sso"   # was "public-protected"
      host: admin.example.com
```

### Traefik middleware names are settings

`public` and `public-sso` ingresses used to attach a fixed middleware
name. You now name it yourself, and an empty name attaches none:

```yaml
ingress:
  middlewares:
    public: "my-no-auth"   # was hardcoded
    publicSso: "my-sso"    # was hardcoded
```

**Do you need to do anything?**

- **You use only `internal` ingresses:** no.
- **You use `public` / `public-sso`:** yes. Set the two values above to
  the middleware names in your cluster. Until you do, no middleware is attached,
  so a `public-sso` ingress will not ask for a login.
- One ingress can override its own with `middlewares:`.

### Smaller default resources

If you never set `workload.resources`, your pods now ask for less:

| | Before | Now |
|-|--------|-----|
| CPU request | `300m` | `100m` |
| Memory request | `512Mi` | `128Mi` |
| CPU limit | `1000m` | none |
| Memory limit | `800Mi` | `512Mi` |

**Apps that need more than 512Mi of memory will be `OOMKilled`.** Keep the old
values by adding them to your values file:

```yaml
workload:
  resources:
    requests: { cpu: 300m, memory: 512Mi }
    limits:   { cpu: 1000m, memory: 800Mi }
```

### Kubernetes 1.30 or newer

The charts refuse to install on older clusters. 1.30 is needed for the
built-in `sleep` used by `shutdownDelaySeconds`.

### Updates, shutdown and Service env vars

Three new defaults. Most apps need nothing.

- **Rolling updates start the new pod first** (`maxUnavailable: 0`, was `1`), so a
  1-replica app no longer goes down on every update. A Deployment with a
  ReadWriteOnce disk from `persistence` now uses `Recreate`.
- **Stopping pods wait 5 seconds** before the stop signal (`shutdownDelaySeconds`),
  so in-flight requests aren't dropped. Your own `preStop` replaces it.
  Needs Kubernetes 1.30+.
- **No more `<SERVICE>_PORT` env vars** (`enableServiceLinks: false`). If your app
  reads them, set `workload.enableServiceLinks: true`.

### Pods spread across nodes

Pods now **prefer** to run on different nodes (`topologySpread`, on by default),
so one node failing doesn't take them all. It's a preference, so pods still start
on a single-node cluster. Nothing to do. To turn it off:
`topologySpread.enabled: false`.

### Safer security defaults

Pods now get `seccompProfile: RuntimeDefault`, the main container gets
`allowPrivilegeEscalation: false`, and **no Kubernetes API token is mounted**.

- **Your app calls the Kubernetes API?** Set `serviceAccount.automount: true`.
- Anything else that breaks? Set the specific key to `null`. See [Security](security.md).

---

## 0.1.x to 0.2.0

### What changed

The `app.kubernetes.io/version` label was removed from the pod **selector**.

Kubernetes doesn't allow a Deployment's or StatefulSet's selector to change.
Because the version used to be in the selector, every `appVersion` bump would
have failed with `field is immutable`. Now it can't happen again.

### What you need to do (once per app)

The selector changes one last time, so Kubernetes will refuse a normal upgrade.
Delete the workload object **but keep its pods running**, then upgrade:

```bash
# 1. Remove the Deployment (or StatefulSet) object; pods keep running
kubectl delete deployment <app> -n <namespace> --cascade=orphan
#   or: kubectl delete statefulset <app> -n <namespace> --cascade=orphan

# 2. Upgrade as usual; the new object adopts the running pods
helm upgrade <release> ./charts/app -n <namespace> -f values.yaml
```

Your data is safe: `--cascade=orphan` leaves the pods and their disks alone.

Services don't need anything special. Their selector isn't locked, so Helm
updates it in place.

### Also in 0.2.0 (no action needed)

- **StatefulSet headless Service port:** it now follows `workload.applicationPort`
  (it was always `80`). Helm updates the Service in place. Set
  `service.headless.port` / `targetPort` if you want to keep `80`.
