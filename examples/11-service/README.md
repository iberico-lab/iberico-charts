# 11 · Service type & ports

> **In one line:** Put the app behind a cloud **LoadBalancer**: port 80 outside → 8080 inside.

**Use this when:**
- You need to choose how the app is reached, or add cloud load balancer settings

## Try it

From the repository root:

```bash
helm template demo charts/app -f examples/11-service/values.yaml
```

Open [`values.yaml`](values.yaml). The comments explain each line.

## What you get

- 1 Service of type `LoadBalancer` with an AWS NLB annotation
- Port 80 → container port 8080

## Watch out

- Want a proper URL with HTTPS? Use [Ingress](../../docs/ingress.md) instead

---

Learn more: [Service](../../docs/service.md) · Next: [12 · URLs (ingress)](../12-ingress/README.md)
