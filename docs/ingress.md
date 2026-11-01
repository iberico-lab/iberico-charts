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
    - name: "my-app"
      type: "internal"
```

**Public website:**

```yaml
ingress:
  enabled: true
  ingresses:
    - name: "my-app"
      type: "public"
      host: "my-app.example.com"
      certManagerIssuer: "letsencrypt-prod"   # your production issuer, see gotcha below
```

**Public, but users must log in:**

```yaml
ingress:
  enabled: true
  ingresses:
    - name: "my-app"
      type: "public-protected"
      host: "admin.example.com"
      certManagerIssuer: "letsencrypt-prod"
```

**Want the full Tailscale URL in the install message?** Tell the chart your
tailnet domain (find it in the Tailscale admin console under DNS):

```yaml
ingress:
  tailnetDomain: "tail1234.ts.net"
```

You can list **several** ingresses to get, say, a private and a public URL at the same time.

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
- `servicePort` must match your [Service](service.md) port (default `80`).
- Traefik middlewares must exist in the cluster: `network-no-auth` for `public`,
  `network-sso` for `public-protected`.
- Only **one ingress of each type** per release. Two `public` entries would get
  the same name, so the chart stops with an error.
- `type` must be exactly `internal`, `public` or `public-protected`. Anything
  else stops the render with an error.

---

## All settings (per ingress)

| Setting | Default | What it does |
|---------|---------|--------------|
| `name` | app name | The Service to send traffic to |
| `type` | `internal` | `internal`, `public` or `public-protected` |
| `host` | — | Hostname (required for public types) |
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
