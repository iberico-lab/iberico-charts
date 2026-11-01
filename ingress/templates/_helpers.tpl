{{/*
Render homepage annotations
Usage: {{ include "helm-helpers.homepageAnnotations" (dict "ingress" . "group" "Public" "root" $) }}
*/}}
{{- define "helm-helpers.homepageAnnotations" -}}
gethomepage.dev/enabled: "true"
gethomepage.dev/name: {{ if and .ingress.homepage .ingress.homepage.name }}{{ .ingress.homepage.name | quote }}{{ else }}{{ .ingress.name | default (include "helm-helpers.appName" .root) | quote }}{{ end }}
gethomepage.dev/description: {{ if and .ingress.homepage .ingress.homepage.description }}{{ .ingress.homepage.description | quote }}{{ else }}{{ .ingress.host | default (printf "%s service" (include "helm-helpers.appName" .root)) | quote }}{{ end }}
gethomepage.dev/group: {{ if and .ingress.homepage .ingress.homepage.group }}{{ .ingress.homepage.group | quote }}{{ else }}{{ .group | quote }}{{ end }}
gethomepage.dev/icon: {{ if and .ingress.homepage .ingress.homepage.icon }}{{ .ingress.homepage.icon | quote }}{{ else }}"kubernetes"{{ end }}
{{- end }}
