{{/*
HTTPRoute name: `name`, or the app's name.
Usage: include "ingress.routeName" (dict "route" $r "root" $)
*/}}
{{- define "ingress.routeName" -}}
{{- .route.name | default (include "helm-helpers.fullname" .root) -}}
{{- end }}

{{/*
Hostname of an entry. See helm-helpers.ingressHost.
Usage: include "ingress.host" (dict "entry" $e "where" "ingress.ingresses[0]" "tailscale" true "root" $)
*/}}
{{- define "ingress.host" -}}
{{- include "helm-helpers.ingressHost" (dict "entry" .entry "where" .where "tailscale" .tailscale "values" .root.Values "name" (include "helm-helpers.fullname" .root)) -}}
{{- end }}

{{/*
Tailscale machine name of an internal Ingress: the first label of its host.
Usage: include "ingress.machineName" (dict "entry" $e "where" "ingress.ingresses[0]" "root" $)
*/}}
{{- define "ingress.machineName" -}}
{{- include "ingress.host" (merge (dict "tailscale" true) .) | splitList "." | first -}}
{{- end }}

{{/*
Gateway an HTTPRoute attaches to, as YAML: the route's own `gateway`, else
ingress.types.<type>.gateway, else ingress.gateway (field by field).
Internal and public-sso routes skip ingress.gateway: it is usually the open
public one, so they must name their own Gateway (the private one, or the one
whose entryPoint asks for a login).
Usage: include "ingress.routeGateway" (dict "route" $r "where" "ingress.httpRoutes[0]" "root" $) | fromYaml
*/}}
{{- define "ingress.routeGateway" -}}
{{- $internal := eq .route.type "internal" -}}
{{- $fromType := (get (.root.Values.types | default dict) .route.type | default dict).gateway | default dict -}}
{{- $default := .root.Values.gateway | default dict -}}
{{- if or $internal (eq .route.type "public-sso") }}{{ $default = dict }}{{ end -}}
{{- $gw := merge (deepCopy (.route.gateway | default dict)) (deepCopy $fromType) (deepCopy $default) -}}
{{- if not $gw.name -}}
  {{- if $internal -}}
    {{- fail (printf "%s is type internal: set ingress.types.internal.gateway.name to a Gateway only your private network reaches (internal routes never use ingress.gateway)" .where) -}}
  {{- else if eq .route.type "public-sso" -}}
    {{- fail (printf "%s is type public-sso: set ingress.types.public-sso.gateway.name to the Gateway that asks for a login (public-sso routes never use ingress.gateway)" .where) -}}
  {{- else -}}
    {{- fail (printf "%s: set gateway.name (on the route, in ingress.types.%s.gateway, or in ingress.gateway) to the Gateway this route attaches to" .where .route.type) -}}
  {{- end -}}
{{- end -}}
{{- toYaml $gw -}}
{{- end }}

{{/*
Traefik Middlewares an ingress or route runs, in order: its type's
(ingress.types.<type>.middlewares, e.g. the login), then the entry's own
`middlewares`. The type's come first, so an entry can add middlewares but
never run them before the login, or drop it. A public-sso Ingress whose type
has no middlewares fails, so a page meant to need a login is never published
without one. Routes ("route" true) don't need them: their public-sso Gateway
can ask for the login itself (see ingress.routeGateway).
Usage: include "ingress.middlewares" (dict "entry" . "where" "ingress.ingresses[0]" "root" $ "route" false) | fromYamlArray
*/}}
{{- define "ingress.middlewares" -}}
{{- $type := .entry.type -}}
{{- $fromType := (get (.root.Values.types | default dict) $type | default dict).middlewares | default list -}}
{{- if and (eq $type "public-sso") (not $fromType) (not .route) -}}
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
Validate entries before anything renders:
- every type is internal, public or public-sso
- internal Ingresses (Tailscale, no Traefik) have no middlewares
- no two entries create the same object. Ingress names: internal =>
  <machine name>-internal, public / public-sso => <app>-<type>. HTTPRoute
  names: `name`, or the app's name.
Usage: include "ingress.validate" .
*/}}
{{- define "ingress.validate" -}}
{{- $types := list "internal" "public" "public-sso" -}}
{{- $routes := dict -}}
{{- range $i, $r := .Values.httpRoutes -}}
  {{- if not (has ($r.type | default "") $types) -}}
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
  {{- $where := printf "ingress.ingresses[%d]" $i -}}
  {{- $type := $ing.type | default "" -}}
  {{- if not (has $type $types) -}}
    {{- fail (printf "%s.type must be internal, public or public-sso (got %q)" $where $type) -}}
  {{- end -}}
  {{- $name := printf "%s-%s" (include "helm-helpers.fullname" $) $type -}}
  {{- if eq $type "internal" -}}
    {{- if $ing.middlewares -}}
      {{- fail (printf "%s is type internal, which the Tailscale operator serves without Traefik, so it can't run middlewares: remove middlewares, or use an internal httpRoute" $where) -}}
    {{- end -}}
    {{- $name = printf "%s-internal" (include "ingress.machineName" (dict "entry" $ing "where" $where "root" $)) -}}
  {{- end -}}
  {{- if hasKey $seen $name -}}
    {{- fail (printf "%s would create Ingress %q, which entry %v already creates. Use only one %s ingress per release, or give internal ones different subdomains" $where $name (get $seen $name) $type) -}}
  {{- end -}}
  {{- $_ := set $seen $name $i -}}
{{- end -}}
{{- end }}

{{/*
Backend Service for an entry: serviceName, or the app's own Service.
Usage: include "ingress.serviceName" (dict "ingress" . "root" $)
*/}}
{{- define "ingress.serviceName" -}}
{{- .ingress.serviceName | default (include "helm-helpers.fullname" .root) -}}
{{- end }}
