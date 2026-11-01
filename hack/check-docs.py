#!/usr/bin/env python3
"""Fail if the docs and the settings disagree, in either direction.

1. Every setting in charts/app/values.schema.json must be documented.
2. Every `setting.path` mentioned in docs/, example READMEs, chart READMEs and
   the agent skill (.agents/) must exist in a schema.

Every documented path must appear as `path` somewhere in docs/*.md. Children of
open maps (resources, affinity...) and of subchart blocks are not required.
Usage: hack/check-docs.py <repo-root>
"""
import json, pathlib, re, sys

root = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else ".")
schema = json.loads((root / "charts/app/values.schema.json").read_text())
docs = "\n".join(p.read_text() for p in (root / "docs").glob("*.md"))

# removed (kept in the schema only for a helpful error) or covered elsewhere
SKIP = {"workload.service", "workload.serviceName", "helm-helpers", "global.nameOverride"}

def walk(node, path):
    if path in SKIP or any(path.startswith(s + ".") for s in SKIP):
        return
    if path:
        yield path
    props = node.get("properties")
    if node.get("type") == "object" and props and node.get("additionalProperties") is False:
        for k, v in props.items():
            yield from walk(v, f"{path}.{k}" if path else k)

missing = [p for p in walk(schema, "") if f"`{p}`" not in docs and f"`{p}." not in docs]
# probe fields are documented once, without the workload.<probe> prefix
missing = [p for p in missing if not any(p.startswith(f"workload.{x}Probe.") for x in ("liveness", "readiness", "startup"))
           or f"`{p.rsplit('.', 1)[1]}`" not in docs]
if missing:
    print("Settings missing from the docs:\n  " + "\n  ".join(missing))
    sys.exit(1)
print("docs cover every setting")

# The other direction: every `setting.path` written in the docs, example
# READMEs and the agent skill must exist, so renamed settings can't linger.
full = json.loads(json.dumps(schema))
for sub in ("ingress", "external-secrets"):
    full["properties"][sub] = json.loads((root / f"charts/{sub}/values.schema.json").read_text())
top = "|".join(re.escape(k) for k in full["properties"])
token = re.compile(r"`((?:%s)(?:\.[A-Za-z0-9_-]+(?:\[\])?)+)`" % top)

def exists(node, parts):
    for part in parts:
        if "items" in node:
            node = node["items"]
        props = node.get("properties")
        if props is None:  # free-form map (annotations, environment...): any key is fine
            return node.get("additionalProperties") is not False
        if part.removesuffix("[]") not in props:
            return False
        node = props[part.removesuffix("[]")]
    return True

pages = [*(root / "docs").glob("*.md"), *(root / "examples").glob("*/README.md"),
         *(root / ".agents").rglob("*.md"), *(root / "charts").glob("*/README.md"), root / "README.md"]
unknown = [f"{page.relative_to(root)}:{n}: {m.group(1)}"
           for page in pages for n, line in enumerate(page.read_text().splitlines(), 1)
           for m in token.finditer(line)
           if not m.group(1).endswith((".md", ".yaml", ".json")) and not exists(full, m.group(1).split("."))]
if unknown:
    print("Docs mention settings that don't exist:\n  " + "\n  ".join(unknown))
    sys.exit(1)
print("every setting the docs mention exists")
