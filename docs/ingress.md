# Ingress

> **In one line:** ingress gives your app a **URL**. It can be private (Tailscale),
> public, or public behind a login.

Off by default. Turning it on (`ingress.enabled: true`) creates nothing until
you list `ingresses` or `httpRoutes`.

---

## Which type?

Every URL picks one of three types, whether it's an Ingress or a Gateway API
route:

| Type | Who can open it | HTTPS | Login |
|------|-----------------|-------|-------|
| `internal` | Only devices on your **private network** (Tailscale) | via Tailscale, or your private Gateway | No |
| `public` | **Anyone** on the internet | Let's Encrypt | No |
| `public-sso` | Anyone, **after signing in** (SSO) | Let's Encrypt | Yes |

Not sure? Start with `internal`.

---

## Copy-paste recipes

**Private (Tailscale only)**, no hostname needed. The URL is
`https://<app name>.<your-tailnet>.ts.net`:

```yaml
ingress:
  enabled: true
  tailnetDomain: "tail1234.ts.net"   # optional: prints the full URL after install
  ingresses:
    - type: "internal"
```

**Public website:**

```yaml
ingress:
  enabled: true
  ingresses:
    - type: "public"
      host: "my-app.example.com"
      certManagerIssuer: "letsencrypt-prod"   # your production issuer, see gotcha below
```

**Public, but users must log in** (the login is set once, in
[`ingress.types`](#what-each-type-runs-ingresstypes)):

```yaml
ingress:
  enabled: true
  ingresses:
    - type: "public-sso"
      host: "admin.example.com"
      certManagerIssuer: "letsencrypt-prod"
```

You can list **several** ingresses to get, say, a private and a public URL at the same time.

---

## Hostnames

One rule for every Ingress and route:

- **`host` set:** used as written, e.g. `shop.example.com`.
- **Otherwise:** `<label>.<domain>`, where
  - the label is `subdomain` (default: the app's name), plus
    `-<suffix>` when the environment sets `ingress.types.<type>.suffix`;
  - the domain is `ingress.types.<type>.domain`, else `ingress.domain`.

So an app can leave hostnames out entirely, and each environment supplies
the domain:

```yaml
ingress:
  domain: apps.example.com           # per environment
  types:
    public: { suffix: dev }          # per environment (optional)
  ingresses:
    - type: public                   # shop-dev.apps.example.com
    - type: public-sso
      subdomain: admin               # admin-dev.apps.example.com
```

**Tailscale (`internal` Ingresses) is the exception**, because Tailscale gives
each machine exactly **one label**: `https://<label>.<tailnet>.ts.net`, with no
subdomains. For these, the domain is always `ingress.tailnetDomain`, the label
becomes the Tailscale machine name, and a `host` must look like
`<label>.<tailnetDomain>`. To keep environments apart in one tailnet, set a
suffix rather than dots:

```yaml
ingress:
  tailnetDomain: tail1234.ts.net
  types:
    internal: { suffix: dev-apps }   # per environment
  ingresses:
    - type: internal                 # https://shop-dev-apps.tail1234.ts.net
```

Without a suffix, two environments in the same tailnet would both claim
`shop`, and Tailscale would rename one to `shop-1`. If you want real
subdomains for private URLs (`shop.internal.dev.example.com`), use an internal
route: see [Private URLs on your own domain](#private-urls-on-your-own-domain).

A hostname label must be up to 63 lowercase letters, numbers and `-`. An entry
with no `host` and no domain to build one stops the render.

---

## What each type runs (`ingress.types`)

An app only picks a type. What the type does is set **once per environment**
(cluster), in `ingress.types`, and shared by Ingresses and HTTPRoutes:

```yaml
ingress:
  types:
    internal:
      domain: internal.dev.example.com                   # internal routes
      gateway: { name: private-gateway, namespace: traefik }
    public:
      middlewares: [my-no-auth]          # e.g. plain forwarding, or nothing
    public-sso:
      middlewares: [my-sso]              # the login (required)
```

- `middlewares` are Traefik Middleware objects in the app's namespace. They
  **always run first**. An entry can add its own `middlewares`, which run
  after them, so an app can add (say) a header rewrite but can never run it
  before the login, or drop the login.
- **`public-sso` needs a login middleware.** With
  `ingress.types.public-sso.middlewares` empty, the render stops, so a page
  meant to need a login is never published without one.
- `internal` Ingresses are served by the Tailscale operator, not Traefik, so
  they run no middlewares (an `internal` ingress entry with `middlewares` stops
  the render), and they ignore `types.internal.domain` (Tailscale decides the
  domain). Those two settings apply to internal HTTPRoutes.
- `domain` and `suffix`: see [Hostnames](#hostnames). `gateway` applies to
  HTTPRoutes only: see below.
- On Ingresses, a name with `@` (e.g. `auth@file`, or a Middleware in another
  namespace as `<namespace>-<name>@kubernetescrd`) is passed to Traefik as
  written.

---

## Gateway API routes (HTTPRoute)

[Gateway API](https://gateway-api.sigs.k8s.io/) is the successor to Ingress:
the Ingress API gets no new features. If your cluster has a Gateway (Traefik
can provide one), give the app routes to it. Routes use the same types and
[hostname rule](#hostnames) as Ingresses:

```yaml
ingress:
  enabled: true
  gateway:                           # the Gateway routes attach to by default
    name: traefik-gateway
    namespace: traefik
    sectionName: websecure           # one listener only; "" = every listener
  httpRoutes:
    - type: public
      host: shop.example.com
    - name: shop-api                 # each extra route needs its own name
      type: public
      host: api.example.com
      path: /v1
      servicePort: 8080
```

**Watch out**

- **HTTPS is set on the Gateway**, not on the route. The Gateway's listener
  holds the certificate (cert-manager can fill it in), so there's no
  `certManagerIssuer` here.
- **A Gateway in another namespace must accept routes from yours.** Its listener
  needs `allowedRoutes.namespaces.from: All` (or a selector that matches). If not,
  `kubectl describe httproute` shows `NotAllowedByListeners`.
- The cluster needs the Gateway API CRDs, version 1.0 or newer (the chart uses
  the stable `v1` HTTPRoute). Without them, the install fails with
  `no matches for kind "HTTPRoute"`. On Kubernetes 1.30, install Gateway API
  1.4: 1.5 and newer need Kubernetes 1.31+.
- **Which Gateway:** the route's own `gateway`, else
  `ingress.types.<type>.gateway`, else `ingress.gateway`. An **`internal`
  route never uses `ingress.gateway`**, because that is usually the public one:
  set `ingress.types.internal.gateway`, or the render stops.
- **Order of filters:** the type's `middlewares` (the login), then the route's
  own `middlewares`, then its raw `filters`. `filters` is an escape hatch for
  plain Gateway API filters (header changes, redirects); for anything Traefik,
  use `middlewares`.
- **A Middleware is looked up in the route's own namespace.** It must exist
  where the HTTPRoute ends up. If something copies your routes to another
  namespace or cluster (a virtual cluster syncing to its host, for example),
  the Middleware has to be there, not where you wrote the values. For the same
  reason a route can't use `@` provider references.

### Private URLs on your own domain

A Tailscale Ingress is always `<label>.<tailnet>.ts.net`. For private URLs like
`shop.internal.dev.example.com`, use `internal` routes and a private Gateway:

1. Run a Gateway whose Service only your tailnet reaches (for example Traefik
   with a Service of `loadBalancerClass: tailscale`).
2. Point `*.internal.dev.example.com` at that Gateway's tailnet address: a DNS
   record, or Tailscale split DNS for the zone.
3. Give the Gateway a certificate for `*.internal.dev.example.com` (cert-manager
   with a DNS-01 issuer works without public access).
4. Tell the chart, once per environment:

```yaml
ingress:
  types:
    internal:
      domain: internal.dev.example.com
      gateway: { name: private-gateway, namespace: traefik }
  httpRoutes:
    - type: internal                 # https://shop.internal.dev.example.com
```

Full example: [20 gateway routes](../examples/20-gateway-routes/README.md).

---

## Homepage dashboard

Every ingress and HTTPRoute is added to your [Homepage](https://gethomepage.dev)
dashboard automatically (for routes, Homepage must be set to discover
HTTPRoutes too). Hide one with `homepage: { enabled: false }`. To change how it looks:

```yaml
      homepage:
        name: "My App"
        description: "What it does"        # default: the hostname
        group: "Applications"              # default: Internal, Public or Public SSO
        icon: "kubernetes"
```

---

## Gotchas

- **Public HTTPS uses `letsencrypt-staging` by default.** Browsers will show a
  warning. For real use, set `certManagerIssuer` to your production issuer
  (often `letsencrypt-prod`).
- `ingress.enabled: true` alone creates **no** URL. List what you want in
  `ingresses` or `httpRoutes`.
- `servicePort` must match your [Service](service.md) port (default `80`).
- Only **one Ingress of each type** per release (internal ones may differ by
  `subdomain`). A second would get the same name, so the chart stops with an
  error. Routes can have as many as you like, each with its own `name`.
- `type` must be exactly `internal`, `public` or `public-sso`. Anything
  else stops the render with an error.

---

## All settings

### Per ingress (`ingress.ingresses[]`)

| Setting | Default | What it does |
|---------|---------|--------------|
| `type` | — (required) | `internal`, `public` or `public-sso` |
| `subdomain` | the app's name | First label of the hostname (see [Hostnames](#hostnames)) |
| `host` | built from `subdomain` | Full hostname. `internal`: must be `<label>.<tailnetDomain>` |
| `serviceName` | the app's Service | Send traffic to a different Service |
| `servicePort` | `80` | Service port to send traffic to |
| `servicePortName` | — | Use a named port instead of a number (`internal` only) |
| `certManagerIssuer` | `letsencrypt-staging` | TLS certificate issuer (public types) |
| `tailscaleExpose` | `false` | Turn on Tailscale "serve" (`internal` only) |
| `annotations` | `{}` | Extra annotations (`internal` only) |
| `middlewares` | `[]` | Extra Traefik Middlewares, run after the type's (public types only) |
| `homepage` | shown | `enabled` (default `true`), `name`, `description`, `group`, `icon` |

### Per route (`ingress.httpRoutes[]`)

| Setting | Default | What it does |
|---------|---------|--------------|
| `ingress.httpRoutes[].type` | — (required) | `internal`, `public` or `public-sso` |
| `ingress.httpRoutes[].subdomain` | the app's name | First label of the hostname |
| `ingress.httpRoutes[].host` | built from `subdomain` | Full hostname, used as written |
| `ingress.httpRoutes[].name` | the app's name | HTTPRoute name; set it when you have more than one route |
| `ingress.httpRoutes[].path` | `/` | Only requests under this path |
| `ingress.httpRoutes[].serviceName` | the app's Service | Send traffic to a different Service |
| `ingress.httpRoutes[].servicePort` | `80` | Service port to send traffic to |
| `ingress.httpRoutes[].gateway` | the type's, else `ingress.gateway` | A different Gateway for this route (`name`, `namespace`, `sectionName`) |
| `ingress.httpRoutes[].middlewares` | `[]` | Extra Traefik Middlewares, run after the type's |
| `ingress.httpRoutes[].filters` | `[]` | Raw Gateway API filters, copied as-is, run last |
| `ingress.httpRoutes[].annotations` | `{}` | Extra annotations |
| `ingress.httpRoutes[].homepage` | shown | Homepage tile, same keys as for ingresses |

### Per environment

| Setting | Default | What it does |
|---------|---------|--------------|
| `ingress.domain` | `""` | Base domain for entries without a `host`, e.g. `apps.example.com` |
| `ingress.tailnetDomain` | `""` | Your tailnet, e.g. `tail1234.ts.net`: the domain of internal Ingresses |
| `ingress.gateway.name` | `""` | Default Gateway for routes |
| `ingress.gateway.namespace` | `""` | The Gateway's namespace; `""` = the app's |
| `ingress.gateway.sectionName` | `""` | Listener name; `""` = every listener |
| `ingress.types.<type>.middlewares` | `[]` | Traefik Middlewares every entry of the type runs first. `public-sso`: required |
| `ingress.types.<type>.domain` | `""` | Base domain for the type; `""` = `ingress.domain` (not used by Tailscale Ingresses) |
| `ingress.types.<type>.suffix` | `""` | Added to the first label with `-`, e.g. `dev` gives `shop-dev.<domain>` |
| `ingress.types.<type>.gateway` | `{}` | Gateway for the type's routes; empty = `ingress.gateway` (`internal`: required, never `ingress.gateway`) |

`<type>` is `internal`, `public` or `public-sso`.

---

## Next

- Examples: [12 ingress](../examples/12-ingress/README.md) · [20 gateway routes](../examples/20-gateway-routes/README.md) · [Service](service.md)
