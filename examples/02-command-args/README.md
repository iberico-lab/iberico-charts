# 02 · Change the start command

> **In one line:** Run the container with your own command instead of the image's default.

**Use this when:**
- You need a different subcommand, a shell script or extra flags

## Try it

From the repository root:

```bash
helm template demo charts/app -f examples/02-command-args/values.yaml
```

Open [`values.yaml`](values.yaml). The comments explain each line.

## What you get

- The main container starts with `command: ["/bin/sh"]`
- …and `args: ["-c", "exec nginx -g 'daemon off;'"]`

## Watch out

- Leave `command` / `args` out (or `[]`) to keep the image's default

---

Learn more: [Workload](../../docs/workload.md) · Next: [03 · Environment variables](../03-environment/README.md)
