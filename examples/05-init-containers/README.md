# 05 · Init containers

> **In one line:** Run setup steps **before** your app starts: wait for a database, then write a file.

**Use this when:**
- Your app must wait for something, or needs a setup step first

## Try it

From the repository root:

```bash
helm template demo charts/app -f examples/05-init-containers/values.yaml
```

Open [`values.yaml`](values.yaml). The comments explain each line.

## What you get

- 2 init containers run in order: `wait-for-db`, then `seed-config`
- Your app starts only after both finish

## Watch out

- Every entry **must** have a `name`
- If an init container never finishes, your app never starts

---

Learn more: [Sidecars & init containers](../../docs/sidecars.md) · Next: [06 · Default health checks](../06-probes-basic/README.md)
