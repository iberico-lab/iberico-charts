# CLAUDE.md

Read **[AGENTS.md](AGENTS.md)** first — it is the entry point for every agent
working in this repo, including this one.

The full operating manual for the charts is the `helm-app-chart` skill at
`.agents/skills/helm-app-chart/SKILL.md` (also available as `/helm-app-chart`
via the symlink in `.claude/skills/`). Read it before writing a values file or
touching anything under `charts/`.

## The two commands that matter most

```bash
make deps    # required once on a fresh clone; renders fail without it
helm template my-app ./charts/app -f values.yaml
```

## Verify, don't assume

Run `helm template` and `helm lint` before claiming a values file works.
`make test` / `make validate` need plugins that may not be installed — if either
is unavailable, say so instead of reporting success.
