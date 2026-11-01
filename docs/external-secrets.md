# External Secrets

## Overview

The `external-secrets:` block pulls secrets from **1Password** and delivers them
to your app two ways: as **environment variables** or as **mounted files**.

## When to use

Use it whenever your app needs credentials (DB passwords, API keys, certs) and
you want them managed in 1Password rather than baked into the image or committed
to git. Off by default.

## How it works

| Delivery | Behavior |
|----------|----------|
| `envVars` | Injected into the main container automatically via `envFrom`. |
| `files` | Mounted at `/etc/secrets/onepassword/` (read-only). Files are base64-encoded. |

Each entry creates an `ExternalSecret` that syncs from the 1Password
`ClusterSecretStore`.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `external-secrets.enabled` | bool | `false` | Enable the subchart |
| `external-secrets.onepassword.enabled` | bool | `false` | Enable 1Password sync |
| `external-secrets.onepassword.refreshInterval` | string | `10m` | Sync interval |
| `external-secrets.onepassword.clusterSecretStoreRef` | string | `onepassword-cluster` | ClusterSecretStore name |
| `external-secrets.onepassword.secrets` | list | `[]` | Secret definitions |
| `external-secrets.onepassword.secrets[].envVars` | list | — | `secretKey` + `mappings` |
| `external-secrets.onepassword.secrets[].files` | list | — | `secretKey` + `mappings` |

## Example

```yaml
external-secrets:
  enabled: true
  onepassword:
    enabled: true
    refreshInterval: "10m"
    clusterSecretStoreRef: onepassword-cluster
    secrets:
      - envVars:
          - secretKey: "credentials-database"
            mappings:
              DATABASE_PASSWORD: password
        files:
          - secretKey: "certificates-tls"
            mappings:
              tls.crt: cert
```

The `mappings` keys become the Kubernetes keys; the values are the 1Password
field names.

## Related

- [Volumes](volumes.md)
- [Values Reference](values-reference.md)
