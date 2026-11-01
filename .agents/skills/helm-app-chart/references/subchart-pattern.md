# The Subchart Pattern

`app` is a **parent chart** that composes reusable subcharts. Consumers enable
bundled capabilities by toggling values; they never add charts themselves.

## How the parent composes subcharts

`app/Chart.yaml` declares dependencies with local `file://` repositories and a
`condition` that maps to a values flag:

```yaml
# app/Chart.yaml
dependencies:
  - name: helm-helpers
    version: "0.1.0"
    repository: "file://../helm-helpers"
  - name: external-secrets
    version: "0.1.0"
    repository: "file://../external-secrets"
    condition: external-secrets.enabled
  - name: ingress
    version: "0.1.0"
    repository: "file://../ingress"
    condition: ingress.enabled
```

Key points:

- `helm-helpers` has **no condition** → always installed. It provides the
  naming/label/selector template functions (`helm-helpers.fullname`,
  `helm-helpers.appName`, `helm-helpers.labels`, `helm-helpers.selectorLabels`,
  `helm-helpers.namespace`) used across every chart.
- `external-secrets` and `ingress` are **gated** by their `enabled` flag. Setting
  `external-secrets.enabled: true` (or `ingress.enabled: true`) activates the
  subchart; its own values live under the same key.
- `app/values.yaml` already contains an empty stub for each subchart
  (`external-secrets: { enabled: false, onepassword: {} }`, `ingress: { enabled:
  false }`), so consumers just fill them in.

Subcharts are resolved into `app/charts/*.tgz` by:

```bash
helm dependency update ./app
```

(The `charts/*.tgz` and `Chart.lock` files are gitignored — regenerate locally.)

## Enabling a bundled subchart

Nothing to add — only toggle values:

```yaml
ingress:
  enabled: true
  ingresses:
    - name: my-app
      type: public
      host: my-app.example.com

external-secrets:
  enabled: true
  onepassword:
    enabled: true
    secrets:
      - envVars:
          - secretKey: credentials-database
            mappings:
              DB_PASSWORD: password
```

## Adding a NEW subchart

To add a new reusable capability (e.g. `monitoring`):

1. **Create the sibling chart** at the repo root, mirroring existing ones:
   `monitoring/Chart.yaml`, `monitoring/values.yaml`, `monitoring/templates/`.
2. **Reuse helm-helpers** by declaring it as a dependency (so naming/labels are
   consistent):

   ```yaml
   # monitoring/Chart.yaml
   apiVersion: v2
   name: monitoring
   version: "0.1.0"
   type: application
   dependencies:
     - name: helm-helpers
       version: "0.1.0"
       repository: "file://../helm-helpers"
   ```

3. **Wire it into the parent** `app/Chart.yaml` with a condition:

   ```yaml
   - name: monitoring
     version: "0.1.0"
     repository: "file://../monitoring"
     condition: monitoring.enabled
   ```

4. **Add a stub to `app/values.yaml`** so the schema is discoverable:

   ```yaml
   monitoring:
     enabled: false
   ```

5. **Resolve and validate**:

   ```bash
   helm dependency update ./app
   helm lint ./app
   helm template my-app ./app -f values-myapp.yaml
   ```

6. If the new subchart needs to inject into the app's pod (env, volumes,
   mounts), extend `app/templates/_helpers.tpl` following the existing
   `external-secrets` handling as the reference implementation.

## Why this pattern

- **One chart to install** per app; features are values toggles.
- **Shared naming/labels** via `helm-helpers` guarantee consistent selectors
  across parent and subcharts.
- **Conditional install** keeps disabled subcharts out of the rendered output.
