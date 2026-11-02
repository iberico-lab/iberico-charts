{{- define "ingress.routeName" -}}
{{- .route.name | default (include "helm-helpers.fullname" .root) -}}
{{- end }}


{{/*
Traefik Middlewares an ingress or route runs, in order: its type's
(ingress.types.<type>.middlewares, e.g. the login), then the entry's own
`middlewares`. The type's come first, so an entry can add middlewares but
never run them before the login, or drop it. A public-sso entry whose type
has no middlewares fails, so a page meant to need a login is never published
without one.
Usage: include "ingress.middlewares" (dict "entry" . "where" "ingress.ingresses[0]" "root" $) | fromYamlArray
*/}}
{{- define "ingress.middlewares" -}}
{{- $type := .entry.type -}}
{{- $fromType := (get (.root.Values.types | default dict) $type | default dict).middlewares | default list -}}
{{- if and (eq $type "public-sso") (not $fromType) -}}
{{- fail (printf "%s is type public-sso, but ingress.types.public-sso.middlewares is empty: list the Traefik Middleware that asks for a login, or the page would be public" .where) -}}
{{- end -}}
{{- toYaml (concat $fromType (.entry.middlewares | default list)) -}}
{{- end }}

{{/*
Homepage group for each type.
Usage: include "ingress.homepageGroup" "public-sso"
*/}}
{{- define "ingress.homepageGroup" -}}
{{- get (dict "internal" "Internal" "public" "Public" "public-sso" "Public SSO") . -}}
{{- end }}

{{/*
Validate ingress entries before anything renders:
- type must be internal, public or public-sso (unknown types used to be
  silently skipped)
- no two entries may produce the same Ingress name (they used to overwrite
  each other). Names: internal => <host|fullname>-internal,
  public / public-sso => <fullname>-<type>.
- no two routes may produce the same HTTPRoute name.
Usage: include "ingress.validate" .
*/}}
{{- define "ingress.validate" -}}
{{- $routes := dict -}}
{{- range $i, $r := .Values.httpRoutes -}}
{{- if not (has ($r.type | default "") (list "internal" "public" "public-sso")) -}}
{{- fail (printf "ingress.httpRoutes[%d].type must be internal, public or public-sso (got %q)" $i ($r.type | default "")) -}}
{{- end -}}
{{- $n := include "ingress.routeName" (dict "route" $r "root" $) -}}
{{- if hasKey $routes $n -}}
{{- fail (printf "ingress.httpRoutes[%d] would create HTTPRoute %q, which entry %v already creates. Give each route its own name" $i $n (get $routes $n)) -}}
{{- end -}}
{{- $_ := set $routes $n $i -}}
{{- end -}}
{{- $seen := dict -}}
{{- range $i, $ing := .Values.ingresses -}}
{{- $type := $ing.type | default "" -}}
{{- if not (has $type (list "internal" "public" "public-sso")) -}}
{{- fail (printf "ingress.ingresses[%d].type must be internal, public or public-sso (got %q)" $i $type) -}}
{{- end -}}
{{- if and (eq $type "internal") $ing.middlewares -}}
{{- fail (printf "ingress.ingresses[%d] is type internal, which the Tailscale operator serves without Traefik, so it can't run middlewares: remove middlewares, or use an internal httpRoute" $i) -}}
{{- end -}}
{{- $name := printf "%s-%s" (include "helm-helpers.fullname" $) $type -}}
{{- if eq $type "internal" -}}
{{- $name = printf "%s-internal" (include "ingress.machineName" (dict "ingress" $ing "root" $ "index" $i)) -}}
{{- end -}}
{{- if hasKey $seen $name -}}
{{- fail (printf "ingress.ingresses[%d] would create Ingress %q, which entry %v already creates. Use only one %s ingress per release." $i $name (get $seen $name) $type) -}}
{{- end -}}
{{- $_ := set $seen $name $i -}}
{{- end -}}
{{- end }}

{{/*
Tailscale machine name for an internal ingress: `host`, or the app's name.
The Tailscale operator takes an Ingress's machine name from the first
spec.tls.hosts entry, and machine names follow DNS label rules: up to 63
lowercase letters, numbers and "-", no dots.
Usage: include "ingress.machineName" (dict "ingress" . "root" $ "index" $i)
*/}}
{{- define "ingress.machineName" -}}
{{- $host := .ingress.host | default (include "helm-helpers.fullname" .root) -}}
{{- if contains "." $host -}}
{{- fail (printf "ingress.ingresses[%v].host %q: for type \"internal\" this is the Tailscale machine name only (e.g. \"shop\"), not a full domain. Put your tailnet (e.g. tail1234.ts.net) in ingress.tailnetDomain." .index $host) -}}
{{- end -}}
{{- if not (regexMatch "^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$" $host) -}}
{{- fail (printf "ingress.ingresses[%v].host %q is not a valid Tailscale machine name: use up to 63 lowercase letters, numbers and \"-\", starting and ending with a letter or number." .index $host) -}}
{{- end -}}
{{- $host -}}
{{- end }}

{{/*
Backend Service for an ingress entry: serviceName, or the app's own Service.
Usage: include "ingress.serviceName" (dict "ingress" . "root" $)
*/}}
{{- define "ingress.serviceName" -}}
{{- .ingress.serviceName | default (include "helm-helpers.fullname" .root) -}}
{{- end }}
