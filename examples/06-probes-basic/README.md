# 06 · Default health checks

> **In one line:** See the built-in health checks working with **zero probe config**. Only the port changes.

**Use this when:**
- Your app answers HTTP on `/` (most web apps do)

## Try it

From the repository root:

```bash
helm template demo charts/app -f examples/06-probes-basic/values.yaml
```

Open [`values.yaml`](values.yaml). The comments explain each line.

## What you get

- Startup, readiness and liveness checks: HTTP `GET /` on port 8080

## Watch out

- Probes follow `applicationPort` on their own, but the Service doesn't. That's why `service.targetPort: 8080` is set

---

Learn more: [Health checks](../../docs/probes.md) · Next: [07 · Change one probe setting](../07-probes-partial-override/README.md)
