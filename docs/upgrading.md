# Upgrading

> **In one line:** read this before you upgrade to a new chart version. It lists
> anything you have to do by hand.

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
  `workload.service.port` / `targetPort` if you want to keep `80`.
