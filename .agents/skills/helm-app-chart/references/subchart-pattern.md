# How the charts fit together

`charts/app` is the only chart people install. It bundles three charts from
the same repo, all released together with the same version:

| Chart | Role | Turned on by |
|-------|------|--------------|
| `charts/helm-helpers` | Library: names, labels, selectors, namespace, version label | always |
| `charts/external-secrets` | 1Password → ExternalSecrets for env vars and files | `external-secrets.enabled` |
| `charts/ingress` | Tailscale (`internal`) and Traefik (`public`, `public-protected`) Ingresses | `ingress.enabled` |

`charts/app/Chart.yaml` lists them with `repository: "file://../<name>"` and a
`condition`. Fetch them with `make deps` (it runs `helm dependency update`; the
`.tgz` files and `Chart.lock` are gitignored).

## Values flow

- A subchart's settings live under its name in the app values:
  `ingress: {...}`, `external-secrets: {...}`. The app's `values.yaml` has a stub
  for each, and the app schema leaves them to the subchart's own
  `values.schema.json`.
- `global.*` (`name` and the name overrides) is shared by every chart, so all
  objects get the same names and labels.
- The app chart **reads** subchart settings where the pod needs them, e.g.
  `app.onepassword.has` decides whether to add `envFrom` and the
  `/etc/secrets/onepassword` mount. Keep that wiring in `charts/app/templates/_helpers.tpl`.

## Adding a new bundled chart

Only for a capability that produces its own objects and that many apps will
toggle. For a one-off, use `extraManifests`; for a pod setting, add it to the app chart.

1. Create `charts/<name>/` with `Chart.yaml` (same version as the others),
   `values.yaml`, `templates/`, `tests/`, `README.md`, `.helmignore`.
2. Depend on `helm-helpers` (`repository: "file://../helm-helpers"`) and use its
   `fullname`, `labels` and `namespace` helpers.
3. Wire it into `charts/app/Chart.yaml` with `condition: <name>.enabled`, and add
   `<name>: { enabled: false }` to `charts/app/values.yaml`.
4. Add its schema to `hack/gen-values-schema.py`, then run `make schema`.
5. Add `docs/<name>.md`, a row in `docs/index.md`, an example, and a CHANGELOG entry.
6. Run `make deps lint test validate examples`.
