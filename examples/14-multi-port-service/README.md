# 14 · Several ports

> **In one line:** Open **three** ports at once: `http`, `grpc` and `metrics`.

**Use this when:**
- Your app serves more than one thing on different ports

## Try it

From the repository root:

```bash
helm template demo charts/app -f examples/14-multi-port-service/values.yaml
```

Open [`values.yaml`](values.yaml). The comments explain each line.

## What you get

- The container opens ports 8080, 9090, 9102
- The Service maps 80 → 8080 (`http`) and passes the other two through

## Watch out

- Port `name`s must **match** between `workload.ports` and `service.ports`

---

Learn more: [Service](../../docs/service.md) · Next: [15 · Config files](../15-config-files/README.md)
