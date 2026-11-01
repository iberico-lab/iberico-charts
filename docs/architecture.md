# Architecture

> **In one line:** `app` is the main chart. It uses three smaller charts, and you
> switch each one on or off in your values file.

You don't need this page to use the chart. It helps when you want to know *why*
things are laid out this way, or where a new feature should go.

---

## The pieces

```text
charts/app  ← you install this one
 ├── helm-helpers      always on   naming + labels (shared code)
 ├── external-secrets  optional    secrets from 1Password
 └── ingress           optional    URLs via Tailscale / Traefik
```

| Chart | What it does | How to turn it on |
|-------|--------------|-------------------|
| `helm-helpers` | Builds names and labels for everything | Always on |
| `external-secrets` | Pulls secrets from 1Password | `external-secrets.enabled: true` |
| `ingress` | Creates private or public URLs | `ingress.enabled: true` |

 Settings for an optional chart go under a key with the **same name**. For
example, ingress settings live under `ingress:`.

---

## How names are picked

Everything the chart creates is named from `global.name`:

```yaml
global:
  name: "my-app"    # → Deployment "my-app", Service "my-app", …
```

| Setting | Default | What it does |
|---------|---------|--------------|
| `global.name` | `""` | The base name. If empty, the **release name** is used. |
| `global.fullnameOverride` | `""` | Wins over `global.name` if set |
| `global.nameOverride` | `""` | Changes the `app.kubernetes.io/name` label only |

Names are made lowercase and cut to 63 characters, which is a Kubernetes limit.
Allowed characters are lowercase letters, digits and `-` (no `_` or `.`). Anything
else stops the render with an error.

**Version label:** every resource gets `app.kubernetes.io/version`. It's your
image tag by default. Set `global.version` to use the same value on everything,
including the ingress and secret objects.

**Namespace:** everything is created in the namespace you install into, so use
`helm install -n <namespace>`.

---

## Adding a new feature chart

1. Create `charts/<new-chart>/` next to the others.
2. Add it to `dependencies:` in `charts/app/Chart.yaml` with `repository: "file://../<new-chart>"` and a `condition:`.
3. Add an empty `<new-chart>:` block to `charts/app/values.yaml` so people can find it.
4. Describe its values in `hack/gen-values-schema.py` and run `make schema`.
5. Add tests in `charts/<new-chart>/tests/` and run `make test`.
6. Run `make lint` to check everything.

---

## Next

- [Values Reference](values-reference.md) — every setting
