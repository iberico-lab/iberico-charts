# 06 - Basic Probes

## What this shows

The default probe behaviour. The chart always renders liveness, readiness, and
startup probes as HTTP `GET /` against `workload.applicationPort`. Here the app
listens on `8080`, so the probes target 8080 without any probe-specific config.

## When to use

As the default for any HTTP app that exposes a health endpoint on the same
port as the app. Start here, then override individual fields only when needed
(see example 07) or supply a fully custom probe (see example 08).

## Render it

```bash
helm template t <repo>/app -f values.yaml
```

## Expected output

The main container includes `livenessProbe`, `readinessProbe`, and
`startupProbe`, each an `httpGet` on path `/` and port `8080`, with the chart's
default timing values.
