{{/*
Render homepage annotations. Renders nothing when homepage.enabled is false.
Usage: {{ include "helm-helpers.homepageAnnotations" (dict "ingress" . "group" "Public" "root" $) }}
*/}}
{{- define "helm-helpers.homepageAnnotations" -}}
{{- $homepage := .ingress.homepage | default dict -}}
{{- if or (not (hasKey $homepage "enabled")) $homepage.enabled -}}
gethomepage.dev/enabled: "true"
gethomepage.dev/name: {{ if and .ingress.homepage .ingress.homepage.name }}{{ .ingress.homepage.name | quote }}{{ else }}{{ .ingress.serviceName | default .ingress.name | default (include "helm-helpers.appName" .root) | quote }}{{ end }}
gethomepage.dev/description: {{ if and .ingress.homepage .ingress.homepage.description }}{{ .ingress.homepage.description | quote }}{{ else }}{{ .ingress.host | default (printf "%s service" (include "helm-helpers.appName" .root)) | quote }}{{ end }}
gethomepage.dev/group: {{ if and .ingress.homepage .ingress.homepage.group }}{{ .ingress.homepage.group | quote }}{{ else }}{{ .group | quote }}{{ end }}
gethomepage.dev/icon: {{ if and .ingress.homepage .ingress.homepage.icon }}{{ .ingress.homepage.icon | quote }}{{ else }}"kubernetes"{{ end }}
{{- end -}}
{{- end }}

{{/*
Validate ingress entries before anything renders:
- type must be internal, public or public-sso (unknown types used to be
  silently skipped)
- no two entries may produce the same Ingress name (they used to overwrite
  each other). Names: internal => <host|fullname>-internal,
  public / public-sso => <fullname>-<type>.
Usage: include "ingress.validate" .
*/}}
{{- define "ingress.routeName" -}}
{{- .route.name | default (include "helm-helpers.fullname" .root) -}}
{{- end }}

{{/*
Hostname of an HTTPRoute, in order: `host` as written, else
`<subdomain>.<domain>`, else `<app name>.<domain>`. Fails when there is no
host and no domain to build one from.
Usage: include "ingress.routeHost" (dict "route" $r "index" $i "domain" $domain "name" $appName)
*/}}
{{- define "ingress.routeHost" -}}
{{- $r := .route -}}
{{- if $r.host -}}
{{- $r.host -}}
{{- else if not .domain -}}
{{- fail (printf "ingress.httpRoutes[%v] has no host: set host (e.g. \"shop.example.com\"), or set ingress.domain (e.g. \"apps.example.com\") to build one from the app name or subdomain" .index) -}}
{{- else -}}
{{- printf "%s.%s" ($r.subdomain | default .name) .domain -}}
{{- end -}}
{{- end }}

{{/*
Filters of an HTTPRoute: the access profile's Middleware (if any), then the
route's own `filters`. `access: sso` without a middleware fails, so a route
meant to need a login is never published without one.
Usage: include "ingress.routeFilters" (dict "route" $r "index" $i "profiles" $.Values.accessProfiles) | fromYamlArray
*/}}
{{- define "ingress.routeFilters" -}}
{{- $r := .route -}}
{{- $filters := list -}}
{{- with $r.access -}}
{{- if not (has . (list "public" "sso")) -}}
{{- fail (printf "ingress.httpRoutes[%v].access must be public or sso (got %q)" $.index .) -}}
{{- end -}}
{{- $profile := get ($.profiles | default dict) . | default dict -}}
{{- if $profile.middleware -}}
{{- $filters = append $filters (dict "type" "ExtensionRef" "extensionRef" (dict "group" "traefik.io" "kind" "Middleware" "name" $profile.middleware)) -}}
{{- else if eq . "sso" -}}
{{- fail (printf "ingress.httpRoutes[%v].access is sso, but ingress.accessProfiles.sso.middleware is empty: set it to the Traefik Middleware that asks for a login, or the route would be public" $.index) -}}
{{- end -}}
{{- end -}}
{{- toYaml (concat $filters ($r.filters | default list)) -}}
{{- end }}

{{- define "ingress.validate" -}}
{{- $routes := dict -}}
{{- range $i, $r := .Values.httpRoutes -}}
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
