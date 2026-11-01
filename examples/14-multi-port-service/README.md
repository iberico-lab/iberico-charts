# 14 - Multi-Port Service

## What this shows

Exposing more than one port. `workload.ports` declares named container ports
(overriding the single default port), and `service.ports` maps them through
the Service with matching `name` entries.

## When to use

When one workload serves multiple protocols on distinct ports — for example
HTTP for users, gRPC for internal callers, and a metrics port for scraping —
and each must be individually addressable through the Service.

## Render it

```bash
helm template t <repo>/charts/app -f values.yaml
```

## Expected output

The main container declares ports `http` (8080), `grpc` (9090), and `metrics`
(9102). The `Service` exposes the same three named ports, forwarding port 80 →
8080 for `http` and pass-through for `grpc` and `metrics`.
