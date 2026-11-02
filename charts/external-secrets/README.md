# external-secrets

Secrets subchart used by the [`app`](https://github.com/iberico-lab/iberico-charts/blob/main/charts/app) chart. It creates
External Secrets Operator `ExternalSecret`s that sync 1Password items into
Kubernetes Secrets, delivered to the app as env vars or files.

You normally don't install it directly: set `external-secrets.enabled: true`
in the `app` chart's values.

```yaml
external-secrets:
  enabled: true
  onepassword:
    secrets:
      - envVars:
          - secretKey: credentials-database   # 1Password item
            mappings:
              DB_PASSWORD: password           # ENV_VAR: 1Password field
```

Needs the External Secrets Operator and a `ClusterSecretStore`
(default name `onepassword-cluster`).

Docs: [External Secrets](https://github.com/iberico-lab/iberico-charts/blob/main/docs/external-secrets.md)
