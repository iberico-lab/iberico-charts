{{/*
Expand the name of the chart.
*/}}
{{- define "helm-helpers.name" -}}
{{- if and .Values.global .Values.global.nameOverride }}
  {{- .Values.global.nameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
  {{- .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- end }}



{{/*
Returns the fully qualified application name.
- Uses .Values.global.fullnameOverride if set, otherwise helm-helpers.appName.
- Always lowercases and truncates to 63 characters.
- Fails unless the result is a valid DNS-1123 label (Kubernetes would
  otherwise reject it only at install time).
Examples:
  - example-service
*/}}
{{- define "helm-helpers.fullname" -}}
{{- $name := include "helm-helpers.appName" . -}}
{{- if .Values.global.fullnameOverride -}}
{{- $name = .Values.global.fullnameOverride | trunc 63 | trimSuffix "-" | lower -}}
{{- end -}}
{{- if not (regexMatch "^[a-z0-9]([-a-z0-9]*[a-z0-9])?$" $name) -}}
{{- fail (printf "invalid name %q (from global.name / global.fullnameOverride / release name): use only lowercase letters, digits and '-', starting and ending with a letter or digit" $name) -}}
{{- end -}}
{{- $name -}}
{{- end }}


{{/*
Returns the base application name, lowercased and truncated to 63 characters:
.Values.global.name if set, otherwise the Helm release name. (Falling back to
the chart name made every release without global.name collide on "app".)
*/}}
{{- define "helm-helpers.appName" -}}
{{- .Values.global.name | default .Release.Name | trunc 63 | trimSuffix "-" | lower -}}

{{- end }}


{{/*
Returns the release namespace (where Helm installs the chart)
*/}}
{{- define "helm-helpers.namespace" -}}
{{- .Release.Namespace | default "default" }}
{{- end }}


{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "helm-helpers.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}


{{/*
Common labels
*/}}
{{- define "helm-helpers.labels" -}}
{{ include "helm-helpers.selectorLabels" . }}
{{ include "helm-helpers.metaLabels" . }}
{{- end }}


{{/*
Selector labels.
Only stable identity labels belong here: Deployment/StatefulSet selectors are
immutable, so anything that changes between releases (e.g. version) must go in
metaLabels instead.
*/}}
{{- define "helm-helpers.selectorLabels" -}}
app.kubernetes.io/name: {{ include "helm-helpers.appName" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}


{{/*
Value for the app.kubernetes.io/version label: the app's image tag, sanitised
to a valid label value (max 63 chars, [A-Za-z0-9._-]). Empty when there's no
tag to read: digest-only images, and the bundled charts, which can't see the
app's values (their Ingresses and ExternalSecrets don't run a version anyway).
*/}}
{{- define "helm-helpers.version" -}}
{{- $v := "" -}}
{{- if and .Values.workload .Values.workload.image .Values.workload.image.tag -}}
{{- $v = .Values.workload.image.tag | toString -}}
{{- end -}}
{{- regexReplaceAll "[^-A-Za-z0-9_.]" $v "-" | trunc 63 | trimAll "-_." -}}
{{- end }}

{{/*
Create unified labels
*/}}
{{- define "helm-helpers.metaLabels" -}}
{{- with include "helm-helpers.version" . -}}
app.kubernetes.io/version: {{ . | quote }}
{{ end -}}
helm.sh/chart: {{ include "helm-helpers.chart" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

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
Hostname of an ingress chart HTTPRoute (shared so the app chart's install
notes print the same URL), in order: `host` as written, else
`<subdomain>.<domain>`, else `<app name>.<domain>`. Fails when there is no
host and no domain to build one from.
Usage: include "helm-helpers.routeHost" (dict "route" $r "index" $i "domain" $domain "name" $appName)
*/}}
{{- define "helm-helpers.routeHost" -}}
{{- $r := .route -}}
{{- if $r.host -}}
{{- $r.host -}}
{{- else if not .domain -}}
{{- fail (printf "ingress.httpRoutes[%v] has no host: set host (e.g. \"shop.example.com\"), or set ingress.domain (e.g. \"apps.example.com\") to build one from the app name or subdomain" .index) -}}
{{- else -}}
{{- printf "%s.%s" ($r.subdomain | default .name) .domain -}}
{{- end -}}
{{- end }}
