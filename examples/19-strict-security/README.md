# 19 · Strict security

> **In one line:** Lock the container down: **not root**, **read-only** filesystem, no extra Linux powers.

**Use this when:**
- The image can run as a normal user (many official images have an `-unprivileged` variant)

## Try it

From the repository root:

```bash
helm template demo charts/app -f examples/19-strict-security/values.yaml
```

Open [`values.yaml`](values.yaml). The comments explain each line.

## What you get

- The container runs as user `101`, never root
- It can't write anywhere except `/tmp`
- All Linux capabilities dropped

## Watch out

- Images that need root or write to their own folders won't start. See [Security](../../docs/security.md) for how to tell
- Mount an `emptyDir` for every folder the app writes to

---

Learn more: [Security](../../docs/security.md)
