# 12 - Ingress

## What this shows

Enabling the bundled `ingress` sub-chart (`ingress.enabled: true`) and
declaring routes in `ingress.ingresses`. This example defines both a `public`
Traefik route (with cert-manager TLS and Homepage annotations) and an
`internal` Tailscale route.

## When to use

When the app must be reachable by hostname. Use `type: public` for
internet-facing HTTPS behind Traefik; `type: internal` for Tailscale-only
access (no public hostname needed); `public-protected` for auth-gated public
access. See `ingress/values.yaml` for the full schema.

## Render it

```bash
helm template t <repo>/app -f values.yaml
```

## Expected output

Two `Ingress` objects: a `public` one for host `app.example.com` with the
`traefik` ingress class, cert-manager issuer, and `gethomepage.dev/*`
annotations; and an `internal` one with the `tailscale` ingress class and a
`defaultBackend` to the Service.
