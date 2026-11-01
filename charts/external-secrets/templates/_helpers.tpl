{{/*
Collect the ExternalSecret `data` entries for one delivery kind across ALL
onepassword.secrets entries, so each kind renders as a single ExternalSecret.
Fails if the same target key (env var name or file name) is mapped twice.
Usage: include "external-secrets.onepassword.data" (dict "config" $config "field" "envVars" "label" "env var")
Returns a YAML list, or "" when there is nothing to render.
*/}}
{{- define "external-secrets.onepassword.data" -}}
{{- $data := list -}}
{{- $seen := dict -}}
{{- range .config.secrets -}}
{{- range (index . $.field) -}}
{{- $secretKey := .secretKey -}}
{{- range $key, $property := .mappings -}}
{{- if hasKey $seen $key -}}
{{- fail (printf "external-secrets: %s %q is mapped more than once in onepassword.secrets" $.label $key) -}}
{{- end -}}
{{- $_ := set $seen $key true -}}
{{- $data = append $data (dict "secretKey" $key "remoteRef" (dict "key" $secretKey "property" $property)) -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- if $data -}}
{{- toYaml $data -}}
{{- end -}}
{{- end }}
