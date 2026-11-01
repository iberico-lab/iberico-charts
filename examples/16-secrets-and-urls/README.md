# 16 · Secrets and URLs (a real web app)

> **In one line:** A typical web app: passwords from **1Password**, a **private** Tailscale URL and a **public** HTTPS URL.

**Use this when:**
- You're deploying a real app with a database password and want it reachable

## Try it

From the repository root:

```bash
helm template demo charts/app -f examples/16-secrets-and-urls/values.yaml
```

Open [`values.yaml`](values.yaml). The comments explain each line.

## What you get

- Env vars `DB_USER` / `DB_PASSWORD` from the 1Password item `shop-database`
- `https://shop.tail1234.ts.net` (Tailscale only)
- `https://shop.example.com` (public, Let's Encrypt)
- Pods restart when the password changes (needs Stakater Reloader)

## Watch out

- Needs the External Secrets Operator, a `onepassword-cluster` ClusterSecretStore, the Tailscale operator, Traefik and cert-manager in the cluster
- Set `ingress.tailnetDomain` to **your** tailnet so the install message prints the right URL

---

Learn more: [External Secrets](../../docs/external-secrets.md) · [Ingress](../../docs/ingress.md) · Next: [17 · High availability](../17-high-availability/README.md)
