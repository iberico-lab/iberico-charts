# 08 · Custom health checks

> **In one line:** Three other kinds of check: raw YAML, a command, and a plain port check.

**Use this when:**
- HTTP on `/` isn't right for your app

## Try it

From the repository root:

```bash
helm template demo charts/app -f examples/08-probes-custom/values.yaml
```

Open [`values.yaml`](values.yaml). The comments explain each line.

## What you get

- Liveness: your **raw** probe YAML, copied as-is (with a custom header)
- Readiness: runs `cat /tmp/healthy`
- Startup: checks that port 8080 is open (TCP)

## Watch out

- `type: exec` **needs** a `command`, or the chart stops with an error

---

Learn more: [Health checks](../../docs/probes.md) · Next: [09 · Keep data (disks)](../09-persistence/README.md)
