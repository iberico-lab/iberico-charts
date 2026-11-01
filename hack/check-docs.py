#!/usr/bin/env python3
"""Fail if a setting in charts/app/values.schema.json isn't documented.

Every documented path must appear as `path` somewhere in docs/*.md. Children of
open maps (resources, affinity...) and of subchart blocks are not required.
Usage: hack/check-docs.py <repo-root>
"""
import json, pathlib, sys

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
