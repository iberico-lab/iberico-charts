# 11 - Service

## What this shows

Configuring the external Service via the top-level `service` block: its
`type` (`ClusterIP` | `NodePort` | `LoadBalancer`), the `port`/`targetPort`
mapping, and provider `annotations`. Here a `LoadBalancer` maps external port
80 to the app's container port 8080.

## When to use

Whenever you need to control how the app is reached from outside the pod
network — choosing a load balancer, pinning a node port, or attaching
cloud-provider annotations. Set `service.enabled: false` to render no Service
at all.

## Render it

```bash
helm template t <repo>/app -f values.yaml
```

## Expected output

A `Service` of type `LoadBalancer` with the NLB annotation, exposing port 80
and forwarding to `targetPort: 8080`, selecting the workload's pods.
