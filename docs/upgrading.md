# Upgrading

> **In one line:** read this before you upgrade to a new chart version. It lists
> anything you have to do by hand.

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
