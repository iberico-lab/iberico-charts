# External Secrets (1Password)

> **In one line:** keep passwords in **1Password**, not in git. The chart copies them
> into your app as **environment variables** or **files**.

Off by default.

---

## Copy-paste starter

```yaml
external-secrets:
  enabled: true                  # the only switch you need
  onepassword:
    secrets:
      - envVars:                       # → environment variables
          - secretKey: "credentials-database"   # 1Password item name
            mappings:
              DB_USER: username        # ENV_VAR_NAME: 1Password field
              DB_PASSWORD: password

        files:                         # → files on disk
          - secretKey: "certificates-tls"
            mappings:
              tls.crt: certificate     # file name: 1Password field
              tls.key: private-key
```

**How to read `mappings`:** the left side is the name **your app** sees.
The right side is the field name **in 1Password**.

---

## Where do the secrets show up?

| You used… | Your app gets… |
|-----------|----------------|
| `envVars` | Environment variables. Nothing else to set up. |
| `files` | Files in **`/etc/secrets/onepassword/`** (read-only), e.g. `/etc/secrets/onepassword/tls.crt` |

The chart syncs from 1Password every `10m` by default.

**Restart the app when a secret changes:** env vars are only read when the app
starts, so a changed password doesn't take effect until the pod restarts. If
[Stakater Reloader](https://github.com/stakater/Reloader) runs in your cluster,
turn this on and it restarts the pods for you:

```yaml
workload:
  reloadOnSecretChange: true
```

---

## Gotchas

- The cluster needs the External Secrets Operator and a `ClusterSecretStore`
  named `onepassword-cluster` (or set `clusterSecretStoreRef`).
- You can list **several** `secrets` entries. They are combined into one secret
  for env vars and one for files. Each env var name and file name may appear
  **only once** across all entries, or the chart stops with an error.
- File contents are copied **as-is**. If a 1Password field holds base64 text,
  the file will contain base64 text.

---

## All settings

| Setting | Default | What it does |
|---------|---------|--------------|
| `external-secrets.enabled` | `false` | Turn the feature on |
| `external-secrets.onepassword.enabled` | `true` | Set `false` to turn 1Password off while keeping the rest |
| `external-secrets.onepassword.refreshInterval` | `10m` | How often to sync |
| `external-secrets.onepassword.clusterSecretStoreRef` | `onepassword-cluster` | Which secret store to use |
| `external-secrets.onepassword.secrets[].envVars[]` | — | `secretKey` + `mappings` → env vars |
| `external-secrets.onepassword.secrets[].files[]` | — | `secretKey` + `mappings` → files |

---

## Next

- [Volumes](volumes.md) · [Workload](workload.md)
