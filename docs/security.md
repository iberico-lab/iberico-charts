# Security

> **In one line:** the chart turns on the safety settings that work with any
> image. One line, `securityPreset: restricted`, switches on the strict ones.

---

## On by default

| Setting | What it does |
|---------|--------------|
| `podSecurityContext.seccompProfile.type: RuntimeDefault` | Blocks unusual system calls |
| `securityContext.allowPrivilegeEscalation: false` | The app can't gain more rights than it starts with |
| `serviceAccount.automount: false` | No Kubernetes API token inside the pod |

Does your app talk to the Kubernetes API? Then turn the token back on:

```yaml
serviceAccount:
  automount: true
```

---

## Stricter: `securityPreset: restricted` (opt-in)

Use this if your image can run as a **non-root** user. Many official images
can't (the default `nginx` image, for example), so test it first.

```yaml
securityPreset: restricted

podSecurityContext:
  runAsUser: 1000                # the user your image expects (if its USER isn't a number)
  fsGroup: 1000                  # lets that user write to mounted disks

securityContext:
  readOnlyRootFilesystem: true   # optional extra; mount an emptyDir for folders it writes to
```

The preset adds everything Kubernetes' strictest built-in level
([restricted Pod Security Standard](https://kubernetes.io/docs/concepts/security/pod-security-standards/#restricted))
asks for, so the pod is accepted in a namespace that enforces it:

| Added | Where |
|-------|-------|
| `runAsNonRoot: true`, `seccompProfile: RuntimeDefault` | Pod |
| `allowPrivilegeEscalation: false`, `capabilities.drop: [ALL]` | Main container, and every sidecar or init container that has no `securityContext` of its own |

Your own `podSecurityContext` / `securityContext` settings are kept on top. A
setting the standard forbids (`runAsUser: 0`, `privileged: true`,
`allowPrivilegeEscalation: true`, adding any capability except
`NET_BIND_SERVICE`) stops the render with an error naming it.

---

## Who can connect (NetworkPolicy, opt-in)

By default, **any pod in the cluster** can connect to your app. A NetworkPolicy
limits that to the pods you choose:

```yaml
networkPolicy:
  enabled: true
  allowSameNamespace: true           # pods in the app's own namespace (the default)
  allowNamespaces:                   # plus everything in these namespaces:
    - traefik                        #   public ingress
    - tailscale                      #   Tailscale ingress proxies
    - monitoring                     #   Prometheus, if you turned on metrics
```

- The app's own pods can always reach each other (StatefulSet peers).
- Only **incoming** traffic is limited. The app can still connect out.
- With `allowSameNamespace: false`, `helm test` still works: its pod is allowed by name.
- Need something else (an IP range, one port only)? Add raw rules to
  `extraIngress`; they're copied as-is.

**Watch out**

- It only works if the cluster's network plugin enforces policies (Calico,
  Cilium, ...). Plain flannel, kindnet, and minikube's default ignore them:
  the policy is accepted, but everything stays open.
- **Forgot a namespace?** The ingress returns 502/504, or Prometheus shows the
  target as down. Find the namespace with `kubectl get pods -A | grep traefik`
  and add it.

---

## Watch out

- Setting `securityContext` or `podSecurityContext` **adds to** the defaults; it
  doesn't replace them. To remove a default, set it to `null`
  (e.g. `allowPrivilegeEscalation: null`).
- `readOnlyRootFilesystem: true` breaks apps that write to their own folders.
  Give them an `emptyDir` [volume](volumes.md) for those paths.
- Without the preset, sidecars and init containers get none of these settings.
  With it, a sidecar that sets its own `securityContext` keeps exactly that, so
  include the restricted settings in it.
- **Pod says `container has runAsNonRoot and image will run as root`?** The
  image's user is root or a name, not a number. Set `podSecurityContext.runAsUser`
  to the user the image expects, or use a non-root build of the image.

---

## Next

- [Volumes](volumes.md) · [Values Reference](values-reference.md)
