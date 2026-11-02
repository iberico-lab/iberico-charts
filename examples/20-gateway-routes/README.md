# 20 · Gateway routes for several environments

> **In one line:** One values file that works in every environment: the domain and the login middleware come from the environment, not the app.

**Use this when:**
- Your cluster has a Gateway (Gateway API) and the same app ships to staging, production and so on
- Some URLs need a login and some don't

## Try it

From the repository root:

```bash
helm template demo charts/app -f examples/20-gateway-routes/values.yaml
# the same app in production: only the environment part changes
helm template demo charts/app -f examples/20-gateway-routes/values.yaml \
  --set ingress.domain=example.com --set ingress.accessProfiles.sso.middleware=prod-sso
```

Open [`values.yaml`](values.yaml). The comments explain each line.

## What you get

- `shop.staging.example.com`: public, with a Homepage tile
- `admin.staging.example.com/admin`: needs a login (the `my-sso` Traefik Middleware is attached as a filter), hidden from Homepage

## Watch out

- `access: sso` with no `accessProfiles.sso.middleware` stops the render, so a page meant to need a login is never published without one
- The Middleware must exist in the namespace the route lands in
- HTTPS is set on the Gateway's listener, not here

---

Learn more: [Ingress](../../docs/ingress.md) · Back to [the list](../README.md)
