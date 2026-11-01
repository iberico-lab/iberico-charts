# 12 · URLs (ingress)

> **In one line:** Give the app two URLs: a **public** one and a **private** Tailscale one.

**Use this when:**
- People (or you) need to open the app in a browser

## Try it

From the repository root:

```bash
helm template demo charts/app -f examples/12-ingress/values.yaml
```

Open [`values.yaml`](values.yaml). The comments explain each line.

## What you get

- Public: `app.example.com` via Traefik, with HTTPS and a Homepage tile
- Private: reachable only over your Tailscale network

## Watch out

- Public HTTPS uses the **staging** issuer by default, so browsers will warn. Set `certManagerIssuer` for real use
- Full settings: `charts/ingress/values.yaml`

---

Learn more: [Ingress](../../docs/ingress.md) · Next: [13 · Database (StatefulSet)](../13-statefulset/README.md)
