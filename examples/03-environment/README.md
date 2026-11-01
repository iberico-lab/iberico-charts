# 03 · Environment variables

> **In one line:** Pass plain settings (log level, mode…) to your app as environment variables.

**Use this when:**
- You have settings that are **not secret**

## Try it

From the repository root:

```bash
helm template demo charts/app -f examples/03-environment/values.yaml
```

Open [`values.yaml`](values.yaml). The comments explain each line.

## What you get

- `NODE_ENV=production`, `LOG_LEVEL=info`, `APP_PORT=80` on the main container

## Watch out

- **Not for passwords!** Use [External Secrets](../../docs/external-secrets.md) for those
- Values are always quoted, so numbers become text (`"80"`)

---

Learn more: [Workload](../../docs/workload.md) · Next: [04 · Sidecars](../04-sidecars/README.md)
