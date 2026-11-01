# 15 · Config files

> **In one line:** Write an nginx config file **right in your values**. Change it and the pods restart by themselves.

**Use this when:**
- Your app reads a config file
- You don't want to manage a separate ConfigMap

## Try it

From the repository root:

```bash
helm template demo charts/app -f examples/15-config-files/values.yaml
```

Open [`values.yaml`](values.yaml). The comments explain each line.

## What you get

- ConfigMap `config-demo-files` holding the file
- The file mounted at `/etc/nginx/conf.d/default.conf`; the rest of the folder is untouched
- A checksum on the pods, so editing the file rolls them

## Watch out

- Not for passwords: ConfigMaps aren't secret. Use [16 · Secrets and URLs](../16-secrets-and-urls/README.md)
- Paths must start with `/`

---

Learn more: [Volumes](../../docs/volumes.md) · Next: [16 · Secrets and URLs (a real web app)](../16-secrets-and-urls/README.md)
