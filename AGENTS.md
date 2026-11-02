# AGENTS.md

Instructions for AI coding agents working in this repository.

**What this repo is:** reusable Helm charts that run an app on Kubernetes from a
short values file. One chart (`charts/app`) installs, three libraries are bundled
into it. Charts are versioned together and never forked per app.

---

## Read in this order

| # | File | Why |
|---|------|-----|
| 1 | `.agents/skills/helm-app-chart/SKILL.md` | The full operating manual: workflow, rules, feature → example map. **Read it before writing any values file.** |
| 2 | `docs/values-reference.md` | Every setting, its default, its type |
| 3 | `charts/app/values.schema.json` | Exact allowed keys. Unknown keys are rejected |
| 4 | `examples/README.md` | 19 working, CI-tested values files |
| 5 | `docs/troubleshooting.md` | What every error message means |

The skill is mirrored for other harnesses at `.claude/skills/helm-app-chart` and
`.opencode/skills/helm-app-chart` (symlinks to `.agents/skills/`). Edit the
canonical file under `.agents/` only.

---

## The task you are most likely doing: deploy an app

```bash
make deps                                  # REQUIRED ONCE, before any render
helm template my-app ./charts/app -f values-my-app.yaml   # render, read output
helm lint   ./charts/app -f values-my-app.yaml
helm install my-app ./charts/app -f values-my-app.yaml -n <namespace>
```

**`make deps` is not optional.** It vendors the three bundled sub-charts into
`charts/*/charts/` (gitignored). Without it every render fails on a missing
dependency. A fresh clone must run it before anything else works.

A complete values file needs only this:

```yaml
workload:
  image:
    repository: ghcr.io/example/app
    tag: "1.2.3"        # always quoted
  applicationPort: 8080 # the port the app listens on
```

Everything else has a working default. Never restate a default in a values file.

### Workflow

1. Pick the closest example from the table in `SKILL.md` and copy its `values.yaml`.
2. Change only what differs for this app.
3. `helm template` and **read the rendered output** — check names, ports, probes,
   mounts against what the app actually needs.
4. `helm lint`.
5. Only then install.

---

## Rules that break a render

- **Maps merge, lists replace.** `readinessProbe: { periodSeconds: 15 }` keeps the
  other probe fields. Setting `volumes`, `persistence`, `extraContainers` or
  `service.ports` replaces the whole list.
- **Quote image tags.** `tag: "1.10"` — unquoted it parses as the number `1.1` and fails.
- **Unknown or misplaced keys fail.** `additional properties 'x' not allowed` means the
  key is wrong *or at the wrong level*. Check `docs/values-reference.md` before moving it.
- **`persistence` is top-level**, not under `workload`. Entries need
  `name`, `size`, `mountPath`.
- **A Deployment with >1 replica cannot share a `ReadWriteOnce` disk.** Use
  `workload.type: StatefulSet`, `replicas: 1`, or a `ReadWriteMany` class.
- **Non-HTTP apps need `type: "tcp"` on all three probes** (`livenessProbe`,
  `readinessProbe`, `startupProbe`) or pods never become ready.
- **Never put passwords in `environment` or `configFiles`.** Use the
  `external-secrets` sub-chart (1Password).
- **The namespace is the release namespace.** Objects render into `-n <ns>`, or the
  kubeconfig context's namespace if `-n` is omitted. It is not a values setting.

---

## Verify before saying you are done

Run these and report the real output:

```bash
helm template my-app ./charts/app -f values-my-app.yaml   # renders without error
helm lint     ./charts/app -f values-my-app.yaml
make examples        # every bundled example still renders
```

If you changed a chart rather than a values file, also run:

```bash
make schema      # after editing values.yaml; edit hack/gen-values-schema.py for new keys
make docs-check  # every setting must be documented
make test        # helm-unittest (needs: helm plugin install https://github.com/helm-unittest/helm-unittest)
make validate    # kubeconform schemas
make version-check
```

`make test` needs the helm-unittest plugin and `make validate` needs kubeconform.
On this machine both are present and pass (108 tests). On a fresh machine they may
not be: if a target errors because the tool is missing, say so — do not claim it passed.

CI (`.github/workflows/lint.yml`) runs: `deps`, `schema-check`, `docs-check`,
`version-check`, `lint`, `test`, `validate`, `examples`. Charts support Kubernetes
**1.30+** and Helm 3 and 4.

---

## Changing the charts themselves

Read `.agents/skills/helm-app-chart/references/conventions.md` first — it holds the
design rules, and breaking one needs a strong reason.

- Every new feature: default in `values.yaml` with a one-line comment, key in
  `hack/gen-values-schema.py`, `make schema`.
- Every new validation `fail` message: add it to `docs/troubleshooting.md`.
- Every new setting: a row in `docs/values-reference.md` and its feature page.
- `CHANGELOG.md` entry, with a `### Breaking` section if anyone has to act.
- Add a unit test under `charts/*/tests` for the happy path and each `fail`.

## Versions

All four charts share one version (currently `0.3.0`). `make bump VERSION=x.y.z`
sets all of them. Before 1.0: breaking → minor, otherwise patch.

Shipping a new **app** release is NOT a chart version change — change
`workload.image.tag` and `helm upgrade`. See `docs/versioning.md`.

---

## Repository map

```
charts/app/              the only chart people install
charts/helm-helpers/     library: names, labels, selectors, namespace
charts/external-secrets/ 1Password → Kubernetes Secrets (condition: external-secrets.enabled)
charts/ingress/          Tailscale (internal) + Traefik (public) (condition: ingress.enabled)
charts/*/templates/      _pod.yaml is shared by Deployment and StatefulSet — edit pod-level things once
charts/*/tests/          helm-unittest suites
docs/                    one page per feature; docs/index.md is the index
examples/NN-*/           working values files, each with a README
tests/e2e/               real-cluster installs (make e2e, needs KUBE_CONTEXT)
hack/                    schema generator and repo checks
Makefile                 canonical dev commands; `make help` lists them
```

## Do not

- Copy or fork `charts/app` per application, or add per-app templates to it.
- Commit `charts/*/charts/`, `Chart.lock` or `*.tgz` (gitignored, vendored by `make deps`).
- Add version or chart labels to selectors or `volumeClaimTemplates` — Kubernetes
  rejects those changes on upgrade.
- Put credentials in committed files, including examples.
