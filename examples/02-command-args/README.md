# 02 - Command and Args

## What this shows

How to override the main container's `command` (entrypoint) and `args`
(arguments) via `workload.command` and `workload.args`. Both render as YAML
lists; when omitted or empty (`[]`) the container inherits the image defaults.

## When to use

When the image's default entrypoint is not what you want in this deployment,
for example to run a specific subcommand, a custom shell script, or to change
runtime flags.

## Render it

```bash
helm template t <repo>/charts/app -f values.yaml
```

## Expected output

The `Deployment`'s main container includes:

```yaml
command:
  - "/bin/sh"
args:
  - "-c"
  - "exec nginx -g 'daemon off;'"
```
