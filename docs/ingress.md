# Ingress

## Overview

The `ingress:` block routes external traffic to your app. It supports three
ingress types, each rendered by the bundled `ingress` subchart.

## When to use

| Type | When to use | Controller |
|------|-------------|------------|
| `internal` | Private access over Tailscale (your tailnet only). | Tailscale |
| `public` | Public HTTPS access from the internet. | Traefik |
| `public-protected` | Public access behind SSO login. | Traefik |

Off by default. Turn on `ingress.enabled: true` and list the ingresses you want.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `ingress.enabled` | bool | `false` | Enable the subchart |
| `ingress.ingresses[].name` | string | — | Backend service name |
| `ingress.ingresses[].type` | string | `internal` | `internal` / `public` / `public-protected` |
| `ingress.ingresses[].host` | string | — | Hostname (required for public types) |
| `ingress.ingresses[].servicePort` | int | `80` | Backend port |
| `ingress.ingresses[].servicePortName` | string | — | Backend port by name |
| `ingress.ingresses[].tailscaleExpose` | bool | `false` | Tailscale serve |
| `ingress.ingresses[].certManagerIssuer` | string | `letsencrypt-staging` | Public TLS issuer |
| `ingress.ingresses[].homepage` | map | — | Homepage entry (`name`, `description`, `group`, `icon`) |

## Example

```yaml
ingress:
  enabled: true
  ingresses:
    - name: "my-app"
      type: "internal"          # tailnet-only
    - name: "my-app"
      type: "public"
      host: "app.example.com"
      servicePort: 80
      homepage:
        name: "My App"
        group: "Applications"
```

## Related

- [Service](service.md)
- [Values Reference](values-reference.md)
