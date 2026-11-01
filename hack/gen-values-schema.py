#!/usr/bin/env python3
"""Generate values.schema.json for the app, ingress and external-secrets charts.

Run `make schema` after adding or changing a value. CI fails if the committed
schemas are out of date. Usage: hack/gen-values-schema.py <repo-root>
"""
import json, pathlib, sys
root = pathlib.Path(sys.argv[1])
D = "http://json-schema.org/draft-07/schema#"
def obj(props, req=(), extra=False, desc=None):
    o = {"type": "object", "properties": props, "additionalProperties": extra}
    if req: o["required"] = list(req)
    if desc: o["description"] = desc
    return o
S  = lambda d=None: {"type": "string", **({"description": d} if d else {})}
B  = lambda d=None: {"type": "boolean", **({"description": d} if d else {})}
I  = lambda d=None, mn=None: {"type": "integer", **({"minimum": mn} if mn is not None else {}), **({"description": d} if d else {})}
ANYMAP = {"type": "object"}
STRMAP = {"type": "object", "additionalProperties": {"type": ["string", "number", "boolean"]}}
LIST = lambda items=ANYMAP, d=None: {"type": "array", "items": items, **({"description": d} if d else {})}
PORT = {"type": "integer", "minimum": 1, "maximum": 65535}
NULLPORT = {"type": ["integer", "null"], "minimum": 1, "maximum": 65535}
GLOBAL = {"type": "object", "description": "Shared with all charts",
          "properties": {"name": S("Base name for all resources (empty = release name)"),
                         "nameOverride": S(), "fullnameOverride": S(),
                         "version": {"type": ["string", "number"], "description": "Version label value"}},
          "additionalProperties": True}

def app():
    probe = obj({
        "enabled": B(), "type": {"enum": ["http", "tcp", "grpc", "exec"]},
        "path": S(), "port": {"type": ["integer", "string", "null"]},
        "host": S(), "scheme": {"enum": ["HTTP", "HTTPS"]},
        "httpHeaders": LIST(), "command": LIST({"type": "string"}), "service": S(),
        "custom": B("Emit spec verbatim"), "spec": ANYMAP,
        "initialDelaySeconds": I(mn=0), "periodSeconds": I(mn=1), "timeoutSeconds": I(mn=1),
        "successThreshold": I(mn=1), "failureThreshold": I(mn=1)})
    svcport = obj({"name": S(), "port": PORT, "targetPort": {"type": ["integer", "string"]},
                   "protocol": {"enum": ["TCP", "UDP", "SCTP"]}}, req=("name", "port"))
    workload = obj({
        "enabled": B(), "type": {"enum": ["Deployment", "StatefulSet"]},
        "annotations": STRMAP, "reloadOnSecretChange": B(),
        "image": obj({"repository": S(), "tag": {"type": ["string", "number"], "description": "Quote it: \"1.10\""},
                      "pullPolicy": {"enum": ["Always", "IfNotPresent", "Never"]}}, req=("repository", "tag")),
        "replicas": I(mn=0), "applicationPort": PORT,
        "ports": LIST(obj({"name": S(), "port": PORT, "protocol": {"enum": ["TCP", "UDP", "SCTP"]}}, req=("name", "port"))),
        "command": LIST({"type": "string"}), "args": LIST({"type": "string"}),
        "pod": obj({"annotations": STRMAP, "labels": STRMAP}),
        "environment": {"type": "object", "additionalProperties": {"type": ["string", "number", "boolean", "null"]}},
        "extraEnv": LIST(), "extraEnvFrom": LIST(),
        "volumes": LIST(obj({"name": S(), "mountPath": S(), "readOnly": B(),
                             "configMap": ANYMAP, "secret": ANYMAP, "emptyDir": ANYMAP,
                             "persistentVolumeClaim": ANYMAP}, req=("name", "mountPath"))),
        "lifecycle": ANYMAP,
        "extraContainers": LIST(obj({"name": S()}, req=("name",), extra=True)),
        "extraInitContainers": LIST(obj({"name": S()}, req=("name",), extra=True)),
        "resources": ANYMAP,
        "livenessProbe": probe, "readinessProbe": probe, "startupProbe": probe,
        "strategy": ANYMAP, "serviceName": S(), "podManagementPolicy": {"enum": ["", "OrderedReady", "Parallel"]},
        "updateStrategy": ANYMAP, "terminationGracePeriodSeconds": I(mn=0),
        "service": obj({"annotations": STRMAP, "port": NULLPORT, "targetPort": {"type": ["integer", "string", "null"]},
                        "ports": LIST(svcport)}),
    })
    service = obj({"enabled": B(), "type": {"enum": ["ClusterIP", "NodePort", "LoadBalancer"]},
                   "port": PORT, "targetPort": {"type": ["integer", "string"]},
                   "portName": {"type": "string", "maxLength": 15}, "annotations": STRMAP, "ports": LIST(svcport)})
    persistence = LIST(obj({"name": S(), "size": S(), "mountPath": S(), "accessModes": LIST({"type": "string"}),
                            "storageClassName": S(), "readOnly": B(), "annotations": STRMAP,
                            "rclone": obj({"storagePath": S(), "umask": {"type": ["string", "number"]}, "annotations": STRMAP})},
                           req=("name", "size", "mountPath")))
    return {"$schema": D, "title": "app chart values", "type": "object", "additionalProperties": False,
            "properties": {
                "global": GLOBAL, "workload": workload, "service": service, "persistence": persistence,
                "serviceAccount": obj({"create": B(), "automount": B(), "name": S(), "annotations": STRMAP}),
                "podSecurityContext": {"type": ["object", "null"]}, "securityContext": {"type": ["object", "null"]},
                "metrics": obj({"serviceMonitor": obj({"enabled": B(), "port": S(), "path": S(),
                                                       "interval": S(), "scrapeTimeout": S(), "labels": STRMAP})}),
                "autoscaling": obj({"enabled": B(), "minReplicas": I(mn=1), "maxReplicas": I(mn=1),
                                    "targetCPUUtilizationPercentage": {"type": ["integer", "null"], "minimum": 1},
                                    "targetMemoryUtilizationPercentage": {"type": ["integer", "null"], "minimum": 1},
                                    "behavior": ANYMAP}),
                "podDisruptionBudget": obj({"enabled": B(),
                                            "minAvailable": {"type": ["integer", "string", "null"]},
                                            "maxUnavailable": {"type": ["integer", "string", "null"]}}),
                "topologySpread": obj({"enabled": B(), "topologyKey": S(), "maxSkew": I(mn=1),
                                       "whenUnsatisfiable": {"enum": ["ScheduleAnyway", "DoNotSchedule"]}}),
                "topologySpreadConstraints": LIST(), "priorityClassName": S(),
                "nodeSelector": STRMAP, "affinity": ANYMAP, "tolerations": LIST(), "imagePullSecrets": LIST(),
                "extraManifests": LIST({"type": ["object", "string"]}),
                "external-secrets": {"type": "object", "description": "See the external-secrets chart"},
                "ingress": {"type": "object", "description": "See the ingress chart"},
                "helm-helpers": {"type": "object"},
            }}

def ingress():
    ing = obj({"name": S("Backend Service name (default: app name)"),
               "type": {"enum": ["internal", "public", "public-protected"]},
               "host": S(), "servicePort": PORT, "servicePortName": S(),
               "certManagerIssuer": S(), "tailscaleExpose": B(), "annotations": STRMAP,
               "homepage": obj({"enabled": B(), "name": S(), "description": S(), "group": S(), "icon": S()})},
              req=("type",))
    return {"$schema": D, "title": "ingress chart values", "type": "object", "additionalProperties": False,
            "properties": {"global": GLOBAL, "enabled": B(), "tailnetDomain": S(), "ingresses": LIST(ing),
                           "helm-helpers": {"type": "object"}}}

def external_secrets():
    entry = obj({"secretKey": S("1Password item"),
                 "mappings": {"type": "object", "additionalProperties": {"type": "string"}, "minProperties": 1}},
                req=("secretKey", "mappings"))
    secret = obj({"envVars": LIST(entry), "files": LIST(entry)})
    op = obj({"enabled": B(), "refreshInterval": S(), "clusterSecretStoreRef": S(), "secrets": LIST(secret)})
    return {"$schema": D, "title": "external-secrets chart values", "type": "object", "additionalProperties": False,
            "properties": {"global": GLOBAL, "enabled": B(), "onepassword": op, "helm-helpers": {"type": "object"}}}

for chart, fn in [("app", app), ("ingress", ingress), ("external-secrets", external_secrets)]:
    (root / "charts" / chart / "values.schema.json").write_text(json.dumps(fn(), indent=2) + "\n")
print("written")
