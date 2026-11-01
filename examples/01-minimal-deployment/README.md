# 01 - Minimal Deployment

## What this shows

The smallest runnable configuration for the `app` chart: one `Deployment`
running `nginx:1.25` with a single container port and a `ClusterIP` Service
in front of it. Everything else inherits the chart defaults (probes, resources,
rolling-update strategy).

## When to use

As the starting point for any stateless web workload, or as the baseline to
copy before layering on more features.

## Render it

```bash
helm template t <repo>/charts/app -f values.yaml
```

## Expected output

Renders a `Deployment` (1 replica, `nginx:1.25`, container port 80) and a
`ClusterIP` `Service` exposing port 80. The three default HTTP probes
(liveness/readiness/startup on `/`) are included automatically.
