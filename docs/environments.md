# Environments

> **In one line:** give every environment one domain, and every app gets
> consistent URLs without writing a hostname.

This page is for whoever runs the cluster. App authors only pick a `type` per
URL (see [Ingress](ingress.md)).

---

## The scheme

Set one value per environment, `ingress.domain`, and the chart builds:

| Type | URL | Reachable from |
|------|-----|----------------|
| `public`, `public-sso` | `<app>.<domain>`, e.g. `shop.dev.apps.example.com` | The internet |
| `internal` (route) | `<app>.internal.<domain>`, e.g. `shop.internal.dev.apps.example.com` | Your tailnet only |
| `internal` (Tailscale Ingress) | `<app>[-<suffix>].<tailnet>.ts.net` | Your tailnet only |

With `domain: dev.apps.example.com` in one cluster and
`domain: prod.apps.example.com` in another, the same app values give:

```
*.dev.apps.example.com             *.prod.apps.example.com
*.internal.dev.apps.example.com    *.internal.prod.apps.example.com
```

An app can still override one URL (`host`, `subdomain`), and the environment
can override a whole type (`ingress.types.<type>.domain`).

---

## What each environment provides

```yaml
ingress:
  domain: dev.apps.example.com
  gateway: { name: public-gateway, namespace: traefik }            # public URLs
  types:
    internal:
      gateway: { name: private-gateway, namespace: traefik-private }  # tailnet only
    public-sso:
      middlewares: [my-sso]                                        # the login
```

Behind those values, the cluster needs two Gateways, DNS and certificates.

### Public URLs

1. **A Gateway with a wildcard listener**, `*.dev.apps.example.com`, on your
   public Traefik. Traefik serves Gateway API with its Kubernetes Gateway
   provider; a listener's port must match a Traefik entryPoint port.
2. **A wildcard certificate.** Annotate the Gateway with
   `cert-manager.io/cluster-issuer` and cert-manager issues a certificate for
   the listener hostname into the Secret named in `certificateRefs`. The
   Secret must be in the Gateway's namespace, and cert-manager needs
   `config.gatewayAPI.enabled=true`. Wildcard certificates from Let's Encrypt
   need a **DNS-01** issuer.
3. **A wildcard DNS record**, `*.dev.apps.example.com`, pointing at the public
   Gateway's address.

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: public-gateway
  namespace: traefik
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-dns01   # your DNS-01 issuer
spec:
  gatewayClassName: traefik
  listeners:
    - name: websecure
      protocol: HTTPS
      port: 8443                    # a Traefik entryPoint port
      hostname: "*.dev.apps.example.com"
      tls:
        mode: Terminate
        certificateRefs: [{ name: dev-apps-wildcard-tls }]
      allowedRoutes:
        namespaces: { from: All }
```

### Internal URLs

1. **A second, private Gateway**, reachable only from your tailnet: for
   example a separate Traefik whose Service has `loadBalancerClass: tailscale`,
   with a listener for `*.internal.dev.apps.example.com`. Keep it a separate
   Gateway rather than another listener on the public one: see "Why two
   Gateways" below.
2. **DNS for `*.internal.dev.apps.example.com`**, one of:
   - **Tailscale split DNS** (a "restricted nameserver"): send queries for
     `internal.dev.apps.example.com` (which covers every name under it) to a
     nameserver your tailnet reaches, e.g. on a `100.x` Tailscale address.
     Only tailnet devices can resolve the names.
   - **A public DNS record** pointing at the private Gateway's `100.x`
     address. Anyone can look the name up, but only tailnet members can
     connect, which Tailscale's docs call relatively harmless.
3. **Its own wildcard certificate**, `*.internal.dev.apps.example.com`. A
   wildcard certificate covers one label only, so `*.dev.apps.example.com`
   does not cover it. DNS-01 works even though the Gateway isn't public.

Tell the chart the private Gateway with `ingress.types.internal.gateway`.
Internal routes never fall back to `ingress.gateway`, so they can't end up on
the public one by mistake.

### Why two Gateways

- A Gateway API listener `*.dev.apps.example.com` matches any depth, so it
  also matches `shop.internal.dev.apps.example.com`. A route that attached to
  the public Gateway with an internal hostname would be accepted there.
- Keeping overlapping listeners on one Gateway apart ("listener isolation")
  is an optional Gateway API feature. Separate Gateways, on separate
  addresses, don't depend on it.
- In public DNS, a wildcard `*.dev.apps.example.com` also answers for
  `x.internal.dev.apps.example.com` unless a record exists under
  `internal.dev.apps.example.com`. Publish the internal records (or use split
  DNS) so internal names never resolve to the public Gateway.

### Without a private Gateway

If you don't run one, use Tailscale Ingresses (`ingresses: [{type: internal}]`)
instead of internal routes. Tailscale names have exactly one label, so set
`ingress.types.internal.suffix` per environment (`shop-dev.<tailnet>.ts.net`)
to keep environments apart in a shared tailnet. See [Ingress](ingress.md#hostnames).

---

## Passing the environment from Flux

Keep the environment block out of every app. Two ways:

**A values ConfigMap per namespace (recommended).** Create, in each app
namespace, a ConfigMap holding the environment's `ingress` settings, and
reference it from every HelmRelease. Values written in the HelmRelease win
over it, so an app can still override a setting:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: ingress-environment
  namespace: shop
data:
  values.yaml: |
    ingress:
      domain: dev.apps.example.com
      gateway: { name: public-gateway, namespace: traefik }
      types:
        internal: { gateway: { name: private-gateway, namespace: traefik-private } }
        public-sso: { middlewares: [my-sso] }
---
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: shop
  namespace: shop
spec:
  chart:
    spec:
      chart: app
      sourceRef: { kind: HelmRepository, name: iberico-charts }
  valuesFrom:
    - kind: ConfigMap
      name: ingress-environment        # must be in the HelmRelease's namespace
  values:
    workload:
      image: { repository: ghcr.io/example/shop, tag: "2.4.1" }
    ingress:
      enabled: true
      httpRoutes:
        - type: public
        - { name: shop-internal, type: internal }
```

**Variable substitution.** A Flux Kustomization's
`postBuild.substituteFrom` replaces `${var}` in everything it applies, so a
HelmRelease can write `domain: ${apps_domain}` and each cluster supplies
`apps_domain` from its own ConfigMap. Simpler for one or two values; the
ConfigMap above keeps the whole block in one place.

---

## Gotchas

- `kubectl describe httproute` showing `NoMatchingListenerHostname`: the
  route's hostname isn't covered by any listener on its Gateway. Check
  `ingress.domain` against the listener's `hostname`.
- `NotAllowedByListeners`: the listener's `allowedRoutes` doesn't include the
  app's namespace.
- Split DNS and exit nodes: a device using an exit node resolves through it
  unless the nameserver has "Use with exit node" turned on.
- Middlewares named in `ingress.types` must exist in each app's namespace
  (HTTPRoutes look them up in their own namespace).

---

## Next

- [Ingress](ingress.md) · Example: [20 gateway routes](../examples/20-gateway-routes/README.md)
