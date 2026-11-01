# Extra manifests

> **In one line:** ship any extra Kubernetes object with your app (a ConfigMap,
> a NetworkPolicy, a CronJob…) without writing a new chart.

---

## Copy-paste starter

```yaml
extraManifests:
  - apiVersion: v1
    kind: ConfigMap
    metadata:
      name: '{{ include "helm-helpers.fullname" . }}-settings'
    data:
      mode: production
```

Each entry is a normal Kubernetes object. Template expressions work inside it,
so you can reuse the app's name (`{{ include "helm-helpers.fullname" . }}`) or the
namespace (`{{ .Release.Namespace }}`).

You can also give an entry as a **string**, which is handy for long or
heavily templated objects:

```yaml
extraManifests:
  - |
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: {{ .Release.Name }}-extra
```

---

## Watch out

- Put template expressions in **quotes** when they start a YAML value
  (`name: '{{ ... }}'`). Otherwise the values file isn't valid YAML.
- These objects are installed, upgraded and deleted together with the release.
- The chart doesn't check these objects. If one is invalid, the install fails.

---

## Next

- [Volumes](volumes.md): mount the ConfigMap you just created
