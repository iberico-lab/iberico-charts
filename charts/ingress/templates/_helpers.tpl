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
- type must be internal, public or public-protected (unknown types used to be
  silently skipped)
- no two entries may produce the same Ingress name (they used to overwrite
  each other). Names: internal => <host|fullname>-internal,
  public / public-protected => <fullname>-<type>.
Usage: include "ingress.validate" .
*/}}
{{- define "ingress.validate" -}}
{{- $seen := dict -}}
{{- range $i, $ing := .Values.ingresses -}}
{{- $type := $ing.type | default "" -}}
{{- if not (has $type (list "internal" "public" "public-protected")) -}}
{{- fail (printf "ingress.ingresses[%d].type must be internal, public or public-protected (got %q)" $i $type) -}}
{{- end -}}
{{- $name := printf "%s-%s" (include "helm-helpers.fullname" $) $type -}}
{{- if eq $type "internal" -}}
{{- $name = printf "%s-internal" ($ing.host | default (include "helm-helpers.fullname" $)) -}}
{{- end -}}
{{- if hasKey $seen $name -}}
{{- fail (printf "ingress.ingresses[%d] would create Ingress %q, which entry %v already creates. Use only one %s ingress per release." $i $name (get $seen $name) $type) -}}
{{- end -}}
{{- $_ := set $seen $name $i -}}
{{- end -}}
{{- end }}

{{/*
Backend Service for an ingress entry: serviceName, then the older `name`
alias, then the app's own Service.
Usage: include "ingress.serviceName" (dict "ingress" . "root" $)
*/}}
{{- define "ingress.serviceName" -}}
{{- .ingress.serviceName | default .ingress.name | default (include "helm-helpers.fullname" .root) -}}
{{- end }}
