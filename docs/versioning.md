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

## Which chart version am I on?

```bash
helm list -n <namespace>          # the CHART column shows e.g. app-0.3.0
```

The APP VERSION column is empty on purpose: these charts can run any app, so
your app's version is the image tag, not something baked into the chart.

## Update to a newer chart version

1. Read [CHANGELOG.md](../CHANGELOG.md) for what changed, and
   [Upgrading](upgrading.md) for any step you must do by hand.
2. Get the new charts (`git pull`, or check out the release tag), then `make deps`.
3. Preview, then upgrade:
   ```bash
   helm template shop ./charts/app -f values-shop.yaml   # does it still render?
   helm upgrade shop ./charts/app -f values-shop.yaml
   helm test shop
   ```

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
    repository: "file://../iberico-charts/charts/app"
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
4. Merge to `main`. Once the release workflow (`.github/workflows/release.yml`)
   is turned on, this publishes the charts.

### Why the charts have no `appVersion`

`appVersion` is meant for "the version of the app this chart ships". These
charts ship no app: you bring the image. A fixed value there would be wrong for
everyone, so it's left out, and the version label comes from your image tag.

---

## Next

- Before a chart update → [Upgrading](upgrading.md)
- Pin the exact image → [Workload](workload.md)
