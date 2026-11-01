# 07 - Partial Probe Overrides

## What this shows

Partial probe overrides. Because the chart merges user values over its
`values.yaml` defaults, you can override a single field (for example
`periodSeconds`) and every other field keeps its default. This example:

- tunes only `livenessProbe.periodSeconds`
- changes only `readinessProbe.path`
- disables `startupProbe` with `enabled: false`

## When to use

When the defaults are almost right and you only need to nudge one or two
settings, avoiding the noise of restating the whole probe block.

## Render it

```bash
helm template t <repo>/app -f values.yaml
```

## Expected output

- `livenessProbe`: HTTP GET `/` on port 8080 with `periodSeconds: 20`.
- `readinessProbe`: HTTP GET `/ready` on port 8080.
- No `startupProbe` block at all.
