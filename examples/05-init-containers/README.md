# 05 - Init Containers (extraInitContainers)

## What this shows

Declaring init containers via `workload.extraInitContainers`. Init containers
run to completion in order before the main container starts. Each entry is
emitted verbatim and **must** define `name`.

## When to use

For bootstrapping that must finish before the app starts: waiting for a
dependency (database, queue), seeding a config volume, running migrations, or
fetching artifacts.

## Render it

```bash
helm template t <repo>/app -f values.yaml
```

## Expected output

The pod spec contains an `initContainers:` list with `wait-for-db` and
`seed-config`, and the main `containers:` list is unchanged.
