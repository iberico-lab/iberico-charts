# 01 · Minimal app

> **In one line:** The smallest working setup: one nginx container plus a Service in front of it.

**Use this when:**
- You're starting a new app and want a clean base to copy

## Try it

From the repository root:

```bash
helm template demo charts/app -f examples/01-minimal-deployment/values.yaml
```

Open [`values.yaml`](values.yaml). The comments explain each line.

## What you get

- 1 Deployment running `nginx:1.25` on port 80
- 1 Service on port 80 (inside the cluster only)
- The 3 default health checks (HTTP `/`)

---

Learn more: [Workload](../../docs/workload.md) · Next: [02 · Change the start command](../02-command-args/README.md)
