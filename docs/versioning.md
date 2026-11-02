# Versions: what to change, and when

> **In one line:** to ship a new version of **your app**, change the **image tag**.
> Chart versions are only for people who change **these charts**.

There are two different versions, and most people only ever touch the first:

| Version | What it is | Where it lives | Who changes it |
|---------|------------|----------------|----------------|
| **Your app's version** | Which build of your app runs | `workload.image.tag` in your values file | You, on every release of your app |
| **Chart version** | Which version of these charts you use | `version:` in `charts/*/Chart.yaml` | Chart maintainers only |

---

## Ship a new version of your app

Change the tag, then upgrade. That's all:

```yaml
workload:
  image:
    repository: ghcr.io/example/shop
    tag: "2.5.0"        # was "2.4.1"
```

```bash
helm upgrade shop ./charts/app -f values-shop.yaml
```

- Kubernetes replaces the pods one by one with the new image.
- The `app.kubernetes.io/version` label follows the tag, so `kubectl get pods
  -L app.kubernetes.io/version` shows what's running.
- Something wrong? Go back: `helm rollback shop` (or set the old tag and upgrade).

**Use a real version as the tag** (`2.5.0`, or a commit SHA), never `latest`.
With `latest`, Kubernetes can't tell that anything changed, so `helm upgrade`
won't roll out the new image, and you can't roll back to a known version.
Want to be sure the exact same image is pulled every time? Also pin the digest:
see [Workload](workload.md).

### What do I change when…

| You… | Change | Chart version? |
|------|--------|----------------|
| Release a new build of your app | `workload.image.tag` (and `digest` if you pin it) | No |
| Change a setting (env var, replicas, URL…) | That setting in your values file | No |
| Want a feature from a newer chart | Update the chart: see below | Yes, by updating |

---

## Where to get the charts

Released versions are served as a Helm repository from GitHub Pages:

```bash
helm repo add iberico https://iberico-lab.github.io/iberico-charts
helm repo update
helm show chart iberico/app --version 0.3.0
```

The site is public, so no login is needed. Each version is also attached to its
GitHub Release as a `.tgz`, which is what the repository index is built from.

## Which chart version am I on?

```bash
helm list -n <namespace>          # the CHART column shows e.g. app-0.3.0
```

The APP VERSION column is empty on purpose: these charts can run any app, so
your app's version is the image tag, not something baked into the chart.

## Update to a newer chart version

1. Read [CHANGELOG.md](../CHANGELOG.md) for what changed, and
   [Upgrading](upgrading.md) for any step you must do by hand.
2. Preview, then upgrade, with the new `--version`:
   ```bash
   helm repo update
   helm template shop iberico/app --version 0.4.0 -f values-shop.yaml   # does it still render?
   helm upgrade shop iberico/app --version 0.4.0 -f values-shop.yaml
   helm test shop
   ```
   Working from a checkout instead? `git pull` (or check out the tag `v0.4.0`),
   `make deps`, and use `./charts/app` in place of `iberico/app`.

If a setting was renamed or removed, the render stops and names the new
setting, so step 3 catches it before anything changes in the cluster.

---

## Wrapping `app` in your own chart (optional)

Most apps only need a values file. If you do keep your own chart, for example
to ship extra templates with it, then **its** `Chart.yaml` versions are yours:

```yaml
# my-shop/Chart.yaml
apiVersion: v2
name: my-shop
version: 1.4.0          # YOUR packaging: bump it whenever anything in my-shop/ changes
appVersion: "2.5.0"     # optional, for `helm list`; keep it equal to the image tag
dependencies:
  - name: app
    version: "0.3.0"    # the iberico-charts version you build on
    repository: "https://iberico-lab.github.io/iberico-charts"  # then: helm dependency update
```

- Your values go **under `app:`** (the dependency's name), except `global:`,
  which stays at the top.
- `appVersion` doesn't set the image or the version label. `app.image.tag` does,
  so bump both together, or leave `appVersion` out.

---

## For chart maintainers

The four charts (`app`, `ingress`, `external-secrets`, `helm-helpers`) are
released **together with one version**. Never edit a `version:` by hand:

```bash
make bump VERSION=0.4.0      # sets every chart version and every dependency pin
```

CI runs `make version-check` and fails if the charts ever disagree.

### Which number to bump

Before 1.0.0 (now):

| The change… | Bump | Example |
|-------------|------|---------|
| Makes someone edit their values or run a step (breaking) | Minor | `0.3.0` → `0.4.0` |
| Adds a setting, or fixes a bug, and nobody has to act | Patch | `0.3.0` → `0.3.1` |
| Only touches docs, examples, tests or CI | Nothing | |

From 1.0.0 on, standard [semver](https://semver.org): breaking → major, new
setting → minor, fix → patch.

### Release checklist

1. `make bump VERSION=x.y.z`
2. In [CHANGELOG.md](../CHANGELOG.md), the notes sit under `## [x.y.z] - unreleased`.
   Replace `unreleased` with today's date.
3. Breaking change? Make sure [Upgrading](upgrading.md) has a section for it.
   Raised the minimum Kubernetes? Change `kubeVersion` in every `Chart.yaml`
   and `MIN_KUBE_VERSION` plus the oldest matrix entry in `.github/workflows/lint.yml`.
4. Merge to `main`, then tag the merge and push the tag:
   ```bash
   git checkout main && git pull
   git tag v0.4.0 && git push origin v0.4.0
   ```
   The release workflow (`.github/workflows/release.yml`) checks the tag matches
   the chart version and the CHANGELOG is dated, then packages all four charts,
   attaches them to a GitHub Release, rebuilds `index.yaml` from every released
   version, and deploys that repository to GitHub Pages at
   `https://iberico-lab.github.io/iberico-charts`. A version that is already
   published is never overwritten: bump instead.

   Pages sites are always public, so the deploy step runs only when the
   repository is public. If you tag while it is private, the Release and its
   `.tgz` files are created and the workflow warns that the site was skipped;
   re-run the workflow after making the repo public to publish it.

### Keeping dependencies up to date

[Renovate](https://docs.renovatebot.com/) (`renovate.json`) opens a PR every
Monday morning when something newer exists: image tags in examples and test
scenarios, the chart's default image, GitHub Actions, Helm, kind, kubeconform,
helm-unittest, and the add-ons the e2e test installs. CI runs on each PR, so a
green one is safe to merge.

- It needs the [Renovate GitHub app](https://github.com/apps/renovate) installed
  on the repository (once).
- Kubernetes versions in the e2e matrix only get patch updates. Moving to a new
  minor is a decision: see the release checklist above.

### Why the charts have no `appVersion`

`appVersion` is meant for "the version of the app this chart ships". These
charts ship no app: you bring the image. A fixed value there would be wrong for
everyone, so it's left out, and the version label comes from your image tag.

---

## Next

- Before a chart update → [Upgrading](upgrading.md)
- Pin the exact image → [Workload](workload.md)
