# Service

> **In one line:** a Service gives your app a **stable address inside the
> cluster**, so other apps (and Ingress) can reach it by name.

**On by default:** port `80` → container port `80`, reachable only inside the cluster.

---

## Copy-paste starter

```yaml
service:
  port: 80            # port other apps connect to
  targetPort: 8080    # port your app listens on
```

---

## Service types

| `service.type` | Who can reach it |
|----------------|------------------|
| `ClusterIP` (default) | Only things inside the cluster |
| `NodePort` | Anyone who can reach a node, on a high port |
| `LoadBalancer` | The internet, through a cloud load balancer |

 For a real URL with HTTPS, keep `ClusterIP` and use [Ingress](ingress.md).

---

## More than one port

Name each port **in the same way** in both places:

```yaml
workload:
  ports:
    - { name: http,    port: 8080, protocol: TCP }
    - { name: metrics, port: 9102, protocol: TCP }

service:
  ports:
    - { name: http,    port: 80,   targetPort: 8080 }
    - { name: metrics, port: 9102, targetPort: 9102 }
```

When `service.ports` is set, `service.port` and `service.targetPort` are ignored.

---

## Gotchas

- **`targetPort` does not follow `workload.applicationPort`.** If your app
  listens on 8080, set `service.targetPort: 8080` yourself.
- StatefulSets **also** get a second "headless" Service named `<app>-cluster`.
  See [StatefulSet](statefulset.md).
- Don't want a Service? Set `service.enabled: false`.
- `workload.enabled: false` also turns off the Service (it would have no pods to send traffic to).

---

## All settings

| Setting | Default | What it does |
|---------|---------|--------------|
| `service.enabled` | `true` | Create the Service |
| `service.type` | `ClusterIP` | Who can reach it (see above) |
| `service.port` | `80` | Port others connect to |
| `service.targetPort` | `80` | Port on your container |
| `service.portName` | `http` | Name of the single port, e.g. `postgres` (max 15 characters) |
| `service.annotations` | `{}` | Extra annotations (e.g. cloud LB settings) |
| `service.ports` | `[]` | Several ports: `name`, `port`, `targetPort`, `protocol` (default `TCP`) |

---

## Next

- Examples: [11 service](../examples/11-service/README.md) · [14 multiple ports](../examples/14-multi-port-service/README.md) · [Ingress](ingress.md)
