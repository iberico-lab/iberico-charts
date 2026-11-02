# 20 · Gateway routes for several environments

> **In one line:** One values file that works in every environment: each URL picks a type (`internal`, `public`, `public-sso`), and the environment decides what that type runs.

**Use this when:**
- Your cluster has a Gateway (Gateway API) and the same app ships to staging, production and so on
- Some URLs need a login, some are private, some are open

## Try it

From the repository root:

```bash
helm template demo charts/app -f examples/20-gateway-routes/values.yaml
# the same app in production: only the environment part changes
helm template demo charts/app -f examples/20-gateway-routes/values.yaml \
  --set ingress.domain=example.com --set 'ingress.types.public-sso.middlewares={prod-sso}'
```

Open [`values.yaml`](values.yaml). The comments explain each line.

## What you get

- `shop.staging.example.com`: public, with a Homepage tile
- `admin.staging.example.com/admin`: the `my-sso` login runs first, then the app's own `shop-admin-headers`; hidden from Homepage
- `ops.internal.staging.example.com`: attached to the private Gateway only

## Watch out

- A `public-sso` URL with no `ingress.types.public-sso.middlewares` stops the render, so a page meant to need a login is never published without one
- An `internal` route can use your own domain (`types.internal.domain`), unlike a Tailscale Ingress, which is always `<one label>.<tailnet>.ts.net`. See [Ingress](../../docs/ingress.md#private-urls-on-your-own-domain)
- An `internal` route needs `ingress.types.internal.gateway`. It never falls back to `ingress.gateway`, which is usually the public one
- Middlewares must exist in the namespace the route lands in
- HTTPS is set on the Gateway's listener, not here

---

Learn more: [Ingress](../../docs/ingress.md) · Back to [the list](../README.md)
