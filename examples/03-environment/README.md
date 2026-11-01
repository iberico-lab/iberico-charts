# 03 - Environment Variables

## What this shows

Declaring plain environment variables with the `workload.environment` map.
Each key/value pair renders as an `env:` entry on the main container, with the
value quoted.

## When to use

For non-sensitive configuration such as log levels, feature flags, or runtime
ports. For secrets, use the `external-secrets` sub-chart instead of putting
them here.

## Render it

```bash
helm template t <repo>/charts/app -f values.yaml
```

## Expected output

The main container contains:

```yaml
env:
  - name: APP_PORT
    value: "80"
  - name: LOG_LEVEL
    value: "info"
  - name: NODE_ENV
    value: "production"
```
