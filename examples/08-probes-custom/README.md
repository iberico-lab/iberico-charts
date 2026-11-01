# 08 - Custom Probes

## What this shows

The three ways to take full control of a probe:

- `livenessProbe` with `custom: true` and a raw `spec` — emitted verbatim,
  including `httpHeaders`.
- `readinessProbe` with `type: "exec"` and a `command` (required for exec).
- `startupProbe` with `type: "tcp"`.

## When to use

When the built-in HTTP/`/` handler is not enough: probes needing custom
headers, host/scheme, exec commands, gRPC, or timing semantics the builder does
not express. The chart still fails loudly on unsupported types or `exec`
without a `command`.

## Render it

```bash
helm template t <repo>/app -f values.yaml
```

## Expected output

- `livenessProbe` matches the verbatim `spec` (httpGet `/live`, header
  `X-Probe`, `periodSeconds: 20`).
- `readinessProbe` is an `exec` probe running `["cat", "/tmp/healthy"]`.
- `startupProbe` is a `tcpSocket` on port 8080.
