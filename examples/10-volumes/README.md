# 10 - Volumes

## What this shows

Mounting pod volumes with `workload.volumes`. Each entry supports exactly one
source: `configMap`, `secret`, `emptyDir`, or `persistentVolumeClaim`
(referencing an existing claim). Each also carries `mountPath` and optional
`readOnly`.

## When to use

When you need to inject configuration or TLS material, provide scratch space,
or bind a pre-existing PVC — without having the chart create the volume for
you. (Chart-managed PVCs live under top-level `persistence`, example 09.)

## Render it

```bash
helm template t <repo>/charts/app -f values.yaml
```

## Expected output

The pod `volumes:` list has `config` (configMap), `tls` (secret), `cache`
(emptyDir), and `existing-data` (persistentVolumeClaim `shared-data-pvc`),
with matching `volumeMounts` on the main container. The `config` and `tls`
mounts are `readOnly: true`.
