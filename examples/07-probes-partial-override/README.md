# 07 · Change one probe setting

> **In one line:** Change **just one field** of a health check. Everything else keeps its default.

**Use this when:**
- The defaults are *almost* right

## Try it

From the repository root:

```bash
helm template demo charts/app -f examples/07-probes-partial-override/values.yaml
```

Open [`values.yaml`](values.yaml). The comments explain each line.

## What you get

- Liveness: checks every **20s** (the rest stays default)
- Readiness: checks **`/ready`** instead of `/`
- Startup: **turned off**

---

Learn more: [Health checks](../../docs/probes.md) · Next: [08 · Custom health checks](../08-probes-custom/README.md)
