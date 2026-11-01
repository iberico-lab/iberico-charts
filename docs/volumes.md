# Volumes

> **In one line:** `workload.volumes` mounts things that **already exist** into
> your container: config files, secrets, temporary folders or existing disks.

Want the chart to **create** a disk for you? Use [Persistence](persistence.md) instead.

---

## The easy way for config files: `configFiles`

Write the file right in your values. Path on the left, contents on the right:

```yaml
workload:
  configFiles:
    /etc/app/config.yaml: |
      log_level: info
      port: 8080
    /etc/nginx/conf.d/default.conf: |
      server { listen 80; location / { root /usr/share/nginx/html; } }
```

The chart creates one ConfigMap (`<app>-files`) and mounts each file at its path.

- **Change a file and the pods restart by themselves** to pick it up.
- Only that one file is added. The rest of the folder (e.g. other files in
  `/etc/nginx/conf.d/`) stays as the image has it.
- Files are read-only. Paths must start with `/`.
- **Not for passwords.** ConfigMaps aren't secret; use [External Secrets](external-secrets.md).
- The volume name `config-files` is taken by this feature.

Need a ConfigMap that something else also manages? Mount it with `volumes` below.

---

## Which source?

| You want to mount… | Use |
|--------------------|-----|
| Config files you write in your values | `configFiles` (above) |
| Config files from a ConfigMap that already exists | `configMap` |
| Passwords or certificates from a Secret | `secret` |
| A temporary folder that is wiped when the pod stops | `emptyDir` |
| A disk you already created yourself | `persistentVolumeClaim` |

---

## Copy-paste starter

```yaml
workload:
  volumes:
    - name: config                 # a ConfigMap, read-only
      mountPath: /etc/config
      readOnly: true
      configMap:
        name: my-app-config

    - name: tls                    # a Secret, read-only
      mountPath: /etc/ssl
      readOnly: true
      secret:
        secretName: my-app-tls

    - name: scratch                # a temporary folder
      mountPath: /tmp/work
      emptyDir: {}

    - name: shared                 # an existing disk
      mountPath: /mnt/shared
      persistentVolumeClaim:
        claimName: shared-data-pvc
```

---

## Gotchas

- **Use one source per entry** (`configMap` *or* `secret` *or* …, not two).
- The ConfigMap, Secret or disk must **already exist** in the namespace.
  If it doesn't, the pod won't start.
- Secrets from 1Password are mounted for you. See [External Secrets](external-secrets.md).

---

## All settings (per list item)

| Setting | What it does |
|---------|--------------|
| `name` | Name of the volume |
| `mountPath` | Folder inside the container |
| `readOnly` | `true` to block writes (default `false`) |
| `configMap.name` / `configMap.items` | ConfigMap to mount (optionally pick keys) |
| `secret.secretName` / `secret.items` | Secret to mount (optionally pick keys) |
| `emptyDir` | `{}` for a temporary folder |
| `persistentVolumeClaim.claimName` | Name of an existing disk |

---

## Next

- Example: [10 volumes](../examples/10-volumes/README.md) · [Persistence](persistence.md)
