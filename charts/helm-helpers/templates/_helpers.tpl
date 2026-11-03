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
Homepage (gethomepage.dev) annotations for an Ingress or HTTPRoute. Renders
nothing when homepage.enabled is false. Each field falls back to a default:
  name         the backend Service, else the entry's name, else the app's name
  description  the entry's hostname
  group        the type's group (Internal, Public, Public SSO)
  icon         "kubernetes"
Usage: include "helm-helpers.homepageAnnotations" (dict "entry" $e "host" $host "group" "Public" "root" $)
*/}}
{{- define "helm-helpers.homepageAnnotations" -}}
{{- $hp := .entry.homepage | default dict -}}
{{- if or (not (hasKey $hp "enabled")) $hp.enabled -}}
{{- $name := .entry.serviceName | default .entry.name | default (include "helm-helpers.appName" .root) -}}
gethomepage.dev/enabled: "true"
gethomepage.dev/name: {{ $hp.name | default $name | quote }}
gethomepage.dev/description: {{ $hp.description | default .host | quote }}
gethomepage.dev/group: {{ $hp.group | default .group | quote }}
gethomepage.dev/icon: {{ $hp.icon | default "kubernetes" | quote }}
{{- end -}}
{{- end }}

{{/*
Hostname of an ingress chart entry (Ingress or HTTPRoute). It lives here
because both the ingress chart and the app chart's install notes need it.

  host set   -> used as written
  otherwise  -> <label>.<domain>
    label  = subdomain (default: the app's name)
    domain = ingress.types.<type>.domain, else ingress.domain; internal
             routes default to "internal.<ingress.domain>", so one
             environment domain gives shop.<domain> and
             shop.internal.<domain> (separate DNS zone and certificate)

Internal Ingresses are Tailscale machines, whose URL is always
<one label>.<tailnet>: their domain is ingress.tailnetDomain, and a `host`
must be <label>.<tailnetDomain>. Without a tailnetDomain the result is just
the label (the machine name); Tailscale adds the tailnet.

Usage: include "helm-helpers.ingressHost" (dict "entry" $e "where" "ingress.ingresses[0]" "tailscale" true "values" $ingressValues "name" $appName)
*/}}
{{- define "helm-helpers.ingressHost" -}}
{{- $v := .values -}}
{{- $type := get ($v.types | default dict) .entry.type | default dict -}}
{{- $host := .entry.host | default "" -}}
{{- if and $host (not .tailscale) -}}
{{- $host -}}
{{- else -}}
  {{- $label := .entry.subdomain | default .name -}}
  {{- $domain := $type.domain | default $v.domain -}}
  {{- if and (eq .entry.type "internal") (not $type.domain) $v.domain -}}
    {{- $domain = printf "internal.%s" $v.domain -}}
  {{- end -}}
  {{- if .tailscale -}}
    {{- $domain = $v.tailnetDomain -}}
    {{- if $host -}}
      {{- $tail := printf ".%s" ($domain | default "<tailnet>") -}}
      {{- if not (and $domain (hasSuffix $tail $host)) -}}
        {{- fail (printf "%s.host %q: a Tailscale URL is <one label>.<tailnet>, e.g. \"shop.tail1234.ts.net\", and needs ingress.tailnetDomain set. Tailscale has no subdomains: use subdomain instead of host, e.g. shop-dev.tail1234.ts.net" .where $host) -}}
      {{- end -}}
      {{- $label = trimSuffix $tail $host -}}
    {{- end -}}
  {{- end -}}
  {{- if not (regexMatch "^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$" $label) -}}
    {{- $from := ternary "host: Tailscale gives each machine one label, so join the parts with \"-\" (e.g. shop-dev-apps), or use subdomain" "subdomain or the app's name" (and .tailscale (ne $host "")) -}}
    {{- fail (printf "%s: hostname label %q must be up to 63 lowercase letters, numbers and \"-\", with no dots (from %s)" .where $label $from) -}}
  {{- end -}}
  {{- if $domain -}}
    {{- printf "%s.%s" $label $domain -}}
  {{- else if .tailscale -}}
    {{- $label -}}
  {{- else -}}
    {{- fail (printf "%s has no host: set host (e.g. \"shop.example.com\"), or set ingress.domain (or ingress.types.%s.domain) to build one from the app's name or subdomain" .where .entry.type) -}}
  {{- end -}}
{{- end -}}
{{- end }}
