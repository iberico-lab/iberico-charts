# Environments

> **In one line:** give every environment one domain and one Gateway per type,
> and every app gets consistent URLs without writing a hostname.

This page is for whoever runs the cluster. App authors only pick a `type` per
URL (see [Ingress](ingress.md)).

---

## The scheme

Set the environment's domain once (`ingress.domain`) and the chart builds:

| Type | URL | Reachable from |
|------|-----|----------------|
| `public-sso` | `<app>.<domain>`, e.g. `shop.dev.apps.example.com` | The internet, after a login |
| `public` | `<app>.<domain>`, or `<app>.public.<domain>` with `types.public.domain` (below) | The internet |
| `internal` (route) | `<app>.internal.<domain>`, e.g. `shop.internal.dev.apps.example.com` | Your tailnet only |

With `domain: dev.apps.example.com` in one cluster and
`domain: prod.apps.example.com` in another, the same app values give:

```
*.dev.apps.example.com             *.prod.apps.example.com
*.public.dev.apps.example.com      *.public.prod.apps.example.com
*.internal.dev.apps.example.com    *.internal.prod.apps.example.com
```

An app can still override one URL (`host`, `subdomain`), and the environment
can override a whole type (`ingress.types.<type>.domain`). Nothing here is
app-specific, so a platform can inject all of it (see
[Passing the environment from Flux](#passing-the-environment-from-flux)).

---

## What each environment provides

```yaml
ingress:
  domain: dev.apps.example.com
  gateway: { name: public-gateway, namespace: traefik }    # the open one
  types:
    public:
      domain: public.dev.apps.example.com                  # optional, see below
    public-sso:
      gateway: { name: sso-gateway, namespace: traefik }   # asks for a login
    internal:
      gateway: { name: internal-gateway, namespace: traefik }  # tailnet only
```

Behind those values, the cluster needs one Gateway per type, each with its
own wildcard listener, certificate and DNS.

### Logins on the Gateway

Gateway API has no Gateway-wide filter, but Traefik does the equivalent per
**entryPoint**: `ports.<entryPoint>.middlewares` (Traefik Helm chart) runs
those middlewares first on every router on that entryPoint, from any
provider, HTTPRoutes included. A route can't opt out. Traefik binds each
Gateway listener to the entryPoint with the same port, so:

| entryPoint | Middlewares | Gateway listener |
|------------|-------------|------------------|
| `websecure` (8443) | your login, e.g. `traefik-sso@kubernetescrd` | `sso-gateway`, `*.dev.apps.example.com` |
| `websecure-public` (8444) | none | `public-gateway`, `*.public.dev.apps.example.com` |
| `websecure-internal` (9443) | none | `internal-gateway`, `*.internal.dev.apps.example.com` |

What that gets you:

- **The login can't be skipped.** Anything attached to `sso-gateway`, chart
  or hand-written, gets it.
- **The login Middleware lives once,** in the Traefik namespace, instead of in
  every app namespace.
- Apps only pick `type: public-sso`. The chart sends those routes to
  `ingress.types.public-sso.gateway` and **never** to `ingress.gateway`, so a
  page meant to need a login can't land on the open Gateway.

Things to know:

- **Whatever reaches the Gateways must pick the entryPoint by hostname**
  (a tunnel, a load balancer). That's why login and no-login apps use
  different hostname patterns (`*.dev.apps…` and `*.public.dev.apps…`).
  Login by default is the safer choice: forgetting the `public.` part gives a
  login, not an open page.
- **The login service itself** (its outpost and callback host) must be on the
  no-login entryPoint, or users loop on the login page.
- **Traefik IngressRoutes with no `entryPoints`** attach to every entryPoint,
  including the login one. Give them explicit `entryPoints`, and set
  `asDefault` only on the one you mean.
- Switching an app between `public` and `public-sso` changes its URL.

Apps can still list their own `middlewares`: they run after the
entryPoint's. `ingress.types.<type>.middlewares` remains for clusters that
put the login on routes instead; Ingresses (no Gateway) still need it for
`public-sso`.

### Each Gateway

1. **A wildcard listener** whose port matches the entryPoint above. Traefik
   serves Gateway API with its Kubernetes Gateway provider.
2. **A wildcard certificate.** Annotate the Gateway with
   `cert-manager.io/cluster-issuer` and cert-manager issues a certificate for
   the listener hostname into the Secret named in `certificateRefs`. The
   Secret must be in the Gateway's namespace, and cert-manager needs
   `config.gatewayAPI.enabled=true`. Wildcard certificates from Let's Encrypt
   need a **DNS-01** issuer. A wildcard covers one label only, so each
   pattern above needs its own.
3. **A wildcard DNS record** pointing at whatever reaches that entryPoint.

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: sso-gateway
  namespace: traefik
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-dns01   # your DNS-01 issuer
spec:
  gatewayClassName: traefik
  listeners:
    - name: websecure
      protocol: HTTPS
      port: 8443                    # the entryPoint with the login
      hostname: "*.dev.apps.example.com"
      tls:
        mode: Terminate
        certificateRefs: [{ name: dev-apps-wildcard-tls }]
      allowedRoutes:
        namespaces: { from: All }
```

### Internal URLs

1. **The internal entryPoint is reachable only from your tailnet**: expose
   it on its own Service with `loadBalancerClass: tailscale`, and keep it off
   anything public.
2. **DNS for `*.internal.dev.apps.example.com`**, one of:
   - **A public DNS record** pointing at that Service's `100.x` Tailscale
     address. Anyone can look the name up, but only tailnet members can
     connect, which Tailscale's docs call relatively harmless.
   - **Tailscale split DNS** (a "restricted nameserver"): send queries for
     `internal.dev.apps.example.com` (which covers every name under it) to a
     nameserver your tailnet reaches. Only tailnet devices can resolve them.
3. **The `100.x` address must stay the same.** It belongs to the Tailscale
   node the operator creates for the Service; if that node is recreated with
   fresh state, it gets a new address and the records break. Keep its state
   Secret, or pin the address in the Tailscale admin console.

Internal routes never fall back to `ingress.gateway`, so they can't end up on
the public one by mistake.

### Why separate Gateways

- A Gateway API listener `*.dev.apps.example.com` matches any depth, so it
  also matches `shop.internal.dev.apps.example.com` and
  `shop.public.dev.apps.example.com`. Only the route's Gateway decides which
  entryPoint (and so which login) serves it. Reject routes whose hostname
  doesn't match their Gateway with an admission policy.
- Keeping overlapping listeners on one Gateway apart ("listener isolation")
  is an optional Gateway API feature. Separate Gateways don't depend on it.
- In public DNS, a wildcard `*.dev.apps.example.com` also answers for
  `x.internal.dev.apps.example.com` unless a record exists under
  `internal.dev.apps.example.com`. Publish the deeper records too.

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
        public:     { domain: public.dev.apps.example.com }
        public-sso: { gateway: { name: sso-gateway, namespace: traefik } }
        internal:   { gateway: { name: internal-gateway, namespace: traefik } }
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
        - type: public-sso
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
  `ingress.domain` / `types.<type>.domain` against the listener's `hostname`.
- `NotAllowedByListeners`: the listener's `allowedRoutes` doesn't include the
  app's namespace.
- Split DNS and exit nodes: a device using an exit node resolves through it
  unless the nameserver has "Use with exit node" turned on.
- Middlewares an app lists itself must exist in the namespace its route
  lands in (HTTPRoutes look them up in their own namespace).

---

## Next

- [Ingress](ingress.md) · Example: [20 gateway routes](../examples/20-gateway-routes/README.md)
