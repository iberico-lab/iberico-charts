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
| `public-protected` | Anyone, **after signing in** (SSO) | Let's Encrypt | Yes |

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

**Public, but users must log in:**

```yaml
ingress:
  enabled: true
  ingresses:
    - type: "public-protected"
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

## Gateway API routes (HTTPRoute)

[Gateway API](https://gateway-api.sigs.k8s.io/) is the successor to Ingress:
the Ingress API gets no new features. If your cluster has a Gateway (Traefik
can provide one), give the app a route to it:

```yaml
ingress:
  enabled: true
  ingresses: []                      # only routes, no Ingress (drop this line to keep both)
  gateway:                           # the Gateway every route attaches to
    name: traefik-gateway
    namespace: traefik
    sectionName: websecure           # one listener only; "" = every listener
  httpRoutes:
    - host: shop.example.com
    - host: api.example.com          # each extra route needs its own name
      name: shop-api
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
- Login (SSO) and other Traefik middlewares: add them as `filters`, e.g.
  `{type: ExtensionRef, extensionRef: {group: traefik.io, kind: Middleware, name: my-sso}}`.
  The Middleware must be in the app's namespace.

### Route settings (`ingress.httpRoutes[]`)

| Setting | Default | What it does |
|---------|---------|--------------|
| `ingress.httpRoutes[].host` | — (required) | The domain |
| `ingress.httpRoutes[].name` | the app's name | HTTPRoute name; set it when you have more than one route |
| `ingress.httpRoutes[].path` | `/` | Only requests under this path |
| `ingress.httpRoutes[].serviceName` | the app's Service | Send traffic to a different Service |
| `ingress.httpRoutes[].servicePort` | `80` | Service port to send traffic to |
| `ingress.httpRoutes[].gateway` | `ingress.gateway` | A different Gateway for this route (`name`, `namespace`, `sectionName`) |
| `ingress.httpRoutes[].filters` | `[]` | Raw Gateway API filters (headers, redirects, middlewares), copied as-is |
| `ingress.httpRoutes[].annotations` | `{}` | Extra annotations |
| `ingress.gateway.name` | `""` | Gateway the routes attach to (required when you have routes) |
| `ingress.gateway.namespace` | `""` | The Gateway's namespace; `""` = the app's |
| `ingress.gateway.sectionName` | `""` | Listener name; `""` = every listener |

---

## Homepage dashboard

Every ingress is added to your [Homepage](https://gethomepage.dev) dashboard
automatically. Hide one with `homepage: { enabled: false }`. To change how it looks:

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
- `public` and `public-protected` **need a `host`**. Without one, the chart stops with an error.
- If you set `ingress.enabled: true` but don't list any `ingresses`, you get
  **one `internal` ingress** by default.
- **For `internal`, `host` is the Tailscale machine name**, not a domain: `store`,
  not `store.tail1234.ts.net`. It must be up to 63 lowercase letters, numbers and
  `-`, otherwise the chart stops with an error. Empty = the app's name. If that
  name is already taken in your tailnet, Tailscale adds a suffix (e.g. `store-1`).
- `servicePort` must match your [Service](service.md) port (default `80`).
- Public ingresses attach a Traefik middleware that you name, in the app's
  namespace: `ingress.middlewares.public` for `public` (plain forwarding) and
  `ingress.middlewares.publicProtected` for `public-protected` (your SSO). Set
  either to `""` (the default) to attach none. One ingress can override its own
  with `middlewares`.
- Only **one ingress of each type** per release. Two `public` entries would get
  the same name, so the chart stops with an error.
- `type` must be exactly `internal`, `public` or `public-protected`. Anything
  else stops the render with an error.

---

## All settings (per ingress)

| Setting | Default | What it does |
|---------|---------|--------------|
| `serviceName` | the app's Service | Send traffic to a different Service |
| `type` | `internal` | `internal`, `public` or `public-protected` |
| `host` | — | Public types: the domain (required). `internal`: the Tailscale machine name (default: the app's name) |
| `servicePort` | `80` | Service port to send traffic to |
| `servicePortName` | — | Use a named port instead of a number (`internal` only) |
| `certManagerIssuer` | `letsencrypt-staging` | TLS certificate issuer (public types) |
| `tailscaleExpose` | `false` | Turn on Tailscale "serve" (`internal` only) |
| `annotations` | `{}` | Extra annotations (`internal` only) |
| `tailnetDomain` (top level, not per ingress) | `""` | Your tailnet, e.g. `tail1234.ts.net`. Only used to print URLs |
| `homepage` | — | `enabled` (default `true`), `name`, `description`, `group`, `icon` |

---

## Next

- Example: [12 ingress](../examples/12-ingress/README.md) · [Service](service.md)
