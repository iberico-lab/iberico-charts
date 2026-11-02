# ingress

Ingress subchart used by the [`app`](https://github.com/iberico-lab/iberico-charts/blob/main/charts/app) chart. It creates
Tailscale (`internal`), Traefik public (`public`) and Traefik + SSO
(`public-sso`) Ingresses, and Gateway API HTTPRoutes of the same three types,
with Homepage annotations. What each type runs (its Traefik Middlewares, and
for routes its Gateway) is set once in `ingress.types`.

You normally don't install it directly: set `ingress.enabled: true` in the
`app` chart's values.

```yaml
ingress:
  enabled: true
  ingresses:
    - type: internal
    - type: public
      host: app.example.com
      certManagerIssuer: letsencrypt-prod
```

Docs: [Ingress](https://github.com/iberico-lab/iberico-charts/blob/main/docs/ingress.md)
