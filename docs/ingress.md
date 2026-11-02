# Ingress

> **In one line:** ingress gives your app a **URL**. It can be private (Tailscale),
> public, or public behind a login.

Off by default.

---

## Which type?

| Type | Who can open it | HTTPS | Login |
|------|-----------------|-------|-------|
| `internal` | Only devices on your **Tailscale** network | via Tailscale | No |
| `public` | **Anyone** on the internet | Let's Encrypt | No |
| `public-sso` | Anyone, **after signing in** (SSO) | Let's Encrypt | Yes |

Not sure? Start with `internal`.

---

## Copy-paste recipes

**Private (Tailscale only)**, no hostname needed:

```yaml
ingress:
  enabled: true
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

**Private, with your own machine name.** The URL becomes
`https://store.<your-tailnet>.ts.net`:

```yaml
ingress:
  enabled: true
  ingresses:
    - type: "internal"
      host: "store"          # the machine name only, not a full domain
```

**Want the full Tailscale URL in the install message?** Tell the chart your
tailnet domain (find it in the Tailscale admin console under DNS):

```yaml
ingress:
  tailnetDomain: "tail1234.ts.net"
```

You can list **several** ingresses to get, say, a private and a public URL at the same time.

---

## What each type runs (`ingress.types`)

An app only picks a type. What the type does is set **once per environment**
(cluster), in `ingress.types`, and shared by Ingresses and HTTPRoutes:

```yaml
ingress:
  types:
    internal:
      gateway: { name: private-gateway, namespace: traefik }  # HTTPRoutes only
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
  the render). `types.internal.middlewares` applies to internal HTTPRoutes.
- `gateway` applies to HTTPRoutes only: see below.
- On Ingresses, a name with `@` (e.g. `auth@file`, or a Middleware in another
  namespace as `<namespace>-<name>@kubernetescrd`) is passed to Traefik as
  written.

---

## Gateway API routes (HTTPRoute)

[Gateway API](https://gateway-api.sigs.k8s.io/) is the successor to Ingress:
the Ingress API gets no new features. If your cluster has a Gateway (Traefik
can provide one), give the app routes to it. Each route has the same `type`
as an ingress:

```yaml
ingress:
  enabled: true
  ingresses: []                      # only routes, no Ingress (drop this line to keep both)
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
  set `ingress.types.internal.gateway` to a Gateway only your private network
  reaches (for example one exposed through Tailscale), or the render stops.
- **Order of filters:** the type's `middlewares` (the login), then the route's
  own `middlewares`, then its raw `filters`.
- **A Middleware is looked up in the route's own namespace.** It must exist
  where the HTTPRoute ends up. If something copies your routes to another
  namespace or cluster (a virtual cluster syncing to its host, for example),
  the Middleware has to be there, not where you wrote the values. For the same
  reason a route can't use `@` provider references.

### Environment hostnames

Write the app's values once and let each environment supply the domain. A
route without `host` gets `<app name>.<domain>`, or `<subdomain>.<domain>`:

```yaml
ingress:
  domain: apps.example.com           # set per environment
  httpRoutes:
    - type: public                   # shop.apps.example.com
    - name: shop-admin
      type: public-sso
      subdomain: admin               # admin.apps.example.com
    - name: shop-legacy
      type: public
      host: shop.example.org         # host is used as written
```

A route with no `host` and no `ingress.domain` stops the render with an error.
Full example: [20 gateway routes](../examples/20-gateway-routes/README.md).

### Route settings (`ingress.httpRoutes[]`)

| Setting | Default | What it does |
|---------|---------|--------------|
| `ingress.httpRoutes[].type` | — (required) | `internal`, `public` or `public-sso` |
| `ingress.httpRoutes[].host` | `<subdomain or app name>.<ingress.domain>` | The full hostname; wins over `subdomain` |
| `ingress.httpRoutes[].subdomain` | the app's name | Hostname is `<subdomain>.<ingress.domain>` |
| `ingress.httpRoutes[].name` | the app's name | HTTPRoute name; set it when you have more than one route |
| `ingress.httpRoutes[].path` | `/` | Only requests under this path |
| `ingress.httpRoutes[].serviceName` | the app's Service | Send traffic to a different Service |
| `ingress.httpRoutes[].servicePort` | `80` | Service port to send traffic to |
| `ingress.httpRoutes[].gateway` | the type's, else `ingress.gateway` | A different Gateway for this route (`name`, `namespace`, `sectionName`) |
| `ingress.httpRoutes[].middlewares` | `[]` | Extra Traefik Middlewares, run after the type's |
| `ingress.httpRoutes[].filters` | `[]` | Raw Gateway API filters (headers, redirects), copied as-is, run last |
| `ingress.httpRoutes[].annotations` | `{}` | Extra annotations |
| `ingress.httpRoutes[].homepage` | shown | Homepage tile, same keys as for ingresses (`enabled: false` hides it) |
| `ingress.gateway.name` | `""` | Default Gateway for routes |
| `ingress.gateway.namespace` | `""` | The Gateway's namespace; `""` = the app's |
| `ingress.gateway.sectionName` | `""` | Listener name; `""` = every listener |
| `ingress.domain` | `""` | Base domain for routes without a `host`, e.g. `apps.example.com` |

### Type settings (`ingress.types`)

| Setting | Default | What it does |
|---------|---------|--------------|
| `ingress.types.internal.middlewares` | `[]` | Middlewares for internal routes (internal Ingresses use Tailscale, no middlewares) |
| `ingress.types.internal.gateway` | `{}` | The private Gateway for internal routes (required by them) |
| `ingress.types.public.middlewares` | `[]` | Middlewares every `public` ingress and route runs first |
| `ingress.types.public.gateway` | `{}` | Gateway for public routes; empty = `ingress.gateway` |
| `ingress.types.public-sso.middlewares` | `[]` | The login middleware(s); required by `public-sso` entries |
| `ingress.types.public-sso.gateway` | `{}` | Gateway for public-sso routes; empty = `ingress.gateway` |

---

## Homepage dashboard

Every ingress and HTTPRoute is added to your [Homepage](https://gethomepage.dev)
dashboard automatically (for routes, Homepage must be set to discover
HTTPRoutes too). Hide one with `homepage: { enabled: false }`. To change how it looks:

```yaml
      homepage:
        name: "My App"
        description: "What it does"
        group: "Applications"
        icon: "kubernetes"
```

---

## Gotchas

- **Public HTTPS uses `letsencrypt-staging` by default.** Browsers will show a
  warning. For real use, set `certManagerIssuer` to your production issuer
  (often `letsencrypt-prod`).
- `public` and `public-sso` **need a `host`**. Without one, the chart stops with an error.
- If you set `ingress.enabled: true` but don't list any `ingresses`, you get
  **one `internal` ingress** by default.
- **For `internal`, `host` is the Tailscale machine name**, not a domain: `store`,
  not `store.tail1234.ts.net`. It must be up to 63 lowercase letters, numbers and
  `-`, otherwise the chart stops with an error. Empty = the app's name. If that
  name is already taken in your tailnet, Tailscale adds a suffix (e.g. `store-1`).
- `servicePort` must match your [Service](service.md) port (default `80`).
- Public ingresses run the middlewares of their type (`ingress.types`), then
  their own `middlewares`. `public-sso` without a login middleware stops the
  render.
- Only **one ingress of each type** per release. Two `public` entries would get
  the same name, so the chart stops with an error.
- `type` must be exactly `internal`, `public` or `public-sso`. Anything
  else stops the render with an error.

---

## All settings (per ingress)

| Setting | Default | What it does |
|---------|---------|--------------|
| `serviceName` | the app's Service | Send traffic to a different Service |
| `type` | `internal` | `internal`, `public` or `public-sso` |
| `host` | — | Public types: the domain (required). `internal`: the Tailscale machine name (default: the app's name) |
| `servicePort` | `80` | Service port to send traffic to |
| `servicePortName` | — | Use a named port instead of a number (`internal` only) |
| `certManagerIssuer` | `letsencrypt-staging` | TLS certificate issuer (public types) |
| `tailscaleExpose` | `false` | Turn on Tailscale "serve" (`internal` only) |
| `annotations` | `{}` | Extra annotations (`internal` only) |
| `middlewares` | `[]` | Extra Traefik Middlewares, run after the type's (public types only) |
| `tailnetDomain` (top level, not per ingress) | `""` | Your tailnet, e.g. `tail1234.ts.net`. Only used to print URLs |
| `homepage` | — | `enabled` (default `true`), `name`, `description`, `group`, `icon` |

---

## Next

- Examples: [12 ingress](../examples/12-ingress/README.md) · [20 gateway routes](../examples/20-gateway-routes/README.md) · [Service](service.md)
