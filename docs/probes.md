# Health checks (probes)

> **In one line:** probes are small checks Kubernetes runs on your app. Their
> results decide when to **send traffic** and when to **restart** it.

**You get all three by default.** They make an HTTP request to `/` on your
app's port. Many apps need no changes here.

---

## The three probes

| Probe | Question it asks | If it fails… |
|-------|------------------|--------------|
| **startup** | "Has the app finished starting?" | Keep waiting (up to ~2.5 min by default) |
| **readiness** | "Can it take requests right now?" | Stop sending it traffic for now |
| **liveness** | "Is it still alive?" | Restart the container |

---

## Copy-paste recipes

**My health endpoint isn't `/`:**

```yaml
workload:
  readinessProbe:
    path: "/healthz"
  livenessProbe:
    path: "/healthz"
```

**My app isn't HTTP (database, queue…)**, so just check that the port is open:

```yaml
workload:
  livenessProbe:  { type: "tcp" }
  readinessProbe: { type: "tcp" }
  startupProbe:   { type: "tcp" }
```

**Check every 15 seconds instead of 5**: change one field and keep the rest.

```yaml
workload:
  readinessProbe:
    periodSeconds: 15
```

**Turn a probe off:**

```yaml
workload:
  startupProbe:
    enabled: false
```

**Run a command as the check:**

```yaml
workload:
  livenessProbe:
    type: "exec"
    command: ["cat", "/tmp/healthy"]    # required for exec
```

**I need full control**: write the raw Kubernetes probe yourself.

```yaml
workload:
  livenessProbe:
    custom: true          # ignore all other fields
    spec:
      httpGet: { path: /live, port: 8080 }
      initialDelaySeconds: 10
```

---

## Gotchas

- `type: exec` **without** `command` stops the render with an error. That's on purpose.
- Only `http`, `tcp`, `grpc` and `exec` are allowed. Anything else is an error.
- A liveness probe that is too strict can restart your app over and over.
  If your app is slow to start, give the **startup** probe more time. Don't loosen liveness.
- There's no shared "health path" setting. Each probe has its own `path`.

---

## All settings

Same keys for `livenessProbe`, `readinessProbe` and `startupProbe`.
Defaults are shown as **liveness / readiness / startup**.

| Setting | Default | What it does |
|---------|---------|--------------|
| `enabled` | `true` / `true` / `true` | Turn the probe on/off |
| `type` | `http` | `http`, `tcp`, `grpc` or `exec` |
| `path` | `/` | URL path (http only) |
| `port` | `null` | `null` = use `workload.applicationPort` |
| `initialDelaySeconds` | `0` / `0` / `5` | Wait this long before the first check |
| `periodSeconds` | `10` / `5` / `5` | Seconds between checks |
| `timeoutSeconds` | `1` / `1` / `3` | How long one check may take |
| `failureThreshold` | `3` / `3` / `30` | Failures in a row before acting |
| `successThreshold` | `1` / `1` / `1` | Successes needed to count as healthy |
| `custom` | `false` | Use `spec` as-is and ignore everything above |
| `spec` | `{}` | Raw probe (only with `custom: true`) |

Extra keys by type: **http** → `host`, `scheme` (`HTTP`/`HTTPS`), `httpHeaders` ·
**tcp** → `host` · **grpc** → `service` · **exec** → `command` (required).

---

## Next

- Examples: [06 basic](../examples/06-probes-basic/README.md) ·
  [07 change one field](../examples/07-probes-partial-override/README.md) ·
  [08 custom](../examples/08-probes-custom/README.md)
