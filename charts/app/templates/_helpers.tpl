
{{/*
Create the name of the service account to use
*/}}
{{- define "app.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "helm-helpers.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}



{{/*
Render a complete probe block (handler + timings) based on type.
When probe.custom is true the probe.spec is emitted verbatim (nothing when spec empty).
Usage: {{ include "app.probe" (dict "probe" .Values.workload.livenessProbe "applicationPort" .Values.workload.applicationPort) }}
*/}}
{{- define "app.probe" -}}
{{- if .probe.custom -}}
{{- with .probe.spec -}}
{{ toYaml . }}
{{- end -}}
{{- else -}}
{{- $type := .probe.type | default "http" -}}
{{- if eq $type "http" -}}
httpGet:
  path: {{ .probe.path | default "/" | quote }}
  port: {{ .probe.port | default .applicationPort }}
  {{- with .probe.host }}
  host: {{ . | quote }}
  {{- end }}
  {{- with .probe.scheme }}
  scheme: {{ . | quote }}
  {{- end }}
  {{- with .probe.httpHeaders }}
  httpHeaders:
    {{- toYaml . | nindent 4 }}
  {{- end }}
{{- else if eq $type "tcp" -}}
tcpSocket:
  port: {{ .probe.port | default .applicationPort }}
  {{- with .probe.host }}
  host: {{ . | quote }}
  {{- end }}
{{- else if eq $type "grpc" -}}
grpc:
  port: {{ .probe.port | default .applicationPort }}
  {{- with .probe.service }}
  service: {{ . | quote }}
  {{- end }}
{{- else if eq $type "exec" -}}
{{- if not .probe.command -}}
{{- fail "app.probe: type=exec requires workload.<probe>.command" -}}
{{- end -}}
exec:
  command:
    {{- toYaml .probe.command | nindent 4 }}
{{- else -}}
{{- fail (printf "app.probe: unsupported probe type %q (use http|tcp|grpc|exec)" $type) -}}
{{- end }}
initialDelaySeconds: {{ .probe.initialDelaySeconds | default 0 }}
periodSeconds: {{ .probe.periodSeconds | default 10 }}
timeoutSeconds: {{ .probe.timeoutSeconds | default 1 }}
successThreshold: {{ .probe.successThreshold | default 1 }}
failureThreshold: {{ .probe.failureThreshold | default 3 }}
{{- end -}}
{{- end }}

{{/*
Decide whether a probe will render non-empty content.
Returns "true" when the probe should be emitted, otherwise "".
A custom probe only renders when it has a non-empty spec (guard against an
empty/null probe block such as `livenessProbe:` with no body).
Usage: {{ if include "app.probeHasContent" (dict "probe" .Values.workload.livenessProbe) }}
*/}}
{{- define "app.probeHasContent" -}}
{{- if .probe.enabled -}}
{{- if .probe.custom -}}
{{- if .probe.spec -}}true{{- end -}}
{{- else -}}true{{- end -}}
{{- end -}}
{{- end }}

{{/*
Render volumeMount configuration
Usage: {{ include "app.volumeMount" . }}
*/}}
{{- define "app.volumeMount" -}}
{{- range .Values.workload.volumes }}
- name: {{ .name }}
  mountPath: {{ .mountPath }}
  {{- if .readOnly }}
  readOnly: true
  {{- end }}
{{- end }}
{{- range .Values.persistence }}
- name: {{ .name }}
  mountPath: {{ .mountPath }}
  {{- if .readOnly }}
  readOnly: true
  {{- end }}
{{- end }}
{{- if and (index .Values "external-secrets") (index .Values "external-secrets" "onepassword") (index .Values "external-secrets" "onepassword" "enabled") (index .Values "external-secrets" "onepassword" "secrets") }}
{{- range (index .Values "external-secrets" "onepassword" "secrets") }}
{{- if .files }}
- name: {{ printf "%s-onepassword-files" (include "helm-helpers.fullname" $) }}
  mountPath: /etc/secrets/onepassword
  readOnly: true
{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Render volume configuration
Usage: {{ include "app.volume" . }}
*/}}
{{- define "app.volume" -}}
{{- range .Values.workload.volumes }}
- name: {{ .name }}
  {{- if .configMap }}
  configMap:
    name: {{ .configMap.name }}
    {{- if .configMap.items }}
    items:
      {{- toYaml .configMap.items | nindent 6 }}
    {{- end }}
  {{- else if .secret }}
  secret:
    secretName: {{ .secret.secretName }}
    {{- if .secret.items }}
    items:
      {{- toYaml .secret.items | nindent 6 }}
    {{- end }}
  {{- else if .emptyDir }}
  emptyDir: {}
  {{- else if .persistentVolumeClaim }}
  persistentVolumeClaim:
    claimName: {{ .persistentVolumeClaim.claimName }}
  {{- end }}
{{- end }}
{{- range .Values.persistence }}
- name: {{ .name }}
  persistentVolumeClaim:
    claimName: {{ printf "%s-%s" (include "helm-helpers.fullname" $) .name }}
{{- end }}
{{- if and (index .Values "external-secrets") (index .Values "external-secrets" "onepassword") (index .Values "external-secrets" "onepassword" "enabled") (index .Values "external-secrets" "onepassword" "secrets") }}
{{- range (index .Values "external-secrets" "onepassword" "secrets") }}
{{- if .files }}
- name: {{ printf "%s-onepassword-files" (include "helm-helpers.fullname" $) }}
  secret:
    secretName: {{ printf "%s-onepassword-files" (include "helm-helpers.fullname" $) }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Render the main application container as a single YAML list item.
Usage: {{- include "app.container" . | nindent 8 }} inside containers:
*/}}
{{- define "app.container" -}}
- name: {{ include "helm-helpers.appName" . }}
  {{- with .Values.securityContext }}
  securityContext:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  image: "{{ .Values.workload.image.repository }}:{{ .Values.workload.image.tag }}"
  imagePullPolicy: {{ .Values.workload.image.pullPolicy }}
  {{- if .Values.workload.command }}
  command:
    {{- range .Values.workload.command }}
    - {{ . | quote }}
    {{- end }}
  {{- end }}
  {{- if .Values.workload.args }}
  args:
    {{- range .Values.workload.args }}
    - {{ . | quote }}
    {{- end }}
  {{- end }}
  ports:
    {{- if .Values.workload.ports }}
    {{- range .Values.workload.ports }}
    - name: {{ .name }}
      containerPort: {{ .port }}
      protocol: {{ .protocol | default "TCP" }}
    {{- end }}
    {{- else }}
    - name: http
      containerPort: {{ .Values.workload.applicationPort }}
      protocol: TCP
    {{- end }}
  {{- if .Values.workload.environment }}
  env:
    {{- range $key, $value := .Values.workload.environment }}
    - name: {{ $key }}
      value: {{ $value | quote }}
    {{- end }}
  {{- end }}
  {{- if and (index .Values "external-secrets") (index .Values "external-secrets" "onepassword") (index .Values "external-secrets" "onepassword" "enabled") (index .Values "external-secrets" "onepassword" "secrets") }}
  {{- $hasEnvVars := false }}
  {{- range (index .Values "external-secrets" "onepassword" "secrets") }}
  {{- if .envVars }}
  {{- $hasEnvVars = true }}
  {{- end }}
  {{- end }}
  {{- if $hasEnvVars }}
  envFrom:
    - secretRef:
        name: {{ printf "%s-onepassword-env" (include "helm-helpers.fullname" .) }}
  {{- end }}
  {{- end }}
  {{- $hasFiles := false }}
  {{- if and (index .Values "external-secrets") (index .Values "external-secrets" "onepassword") (index .Values "external-secrets" "onepassword" "enabled") (index .Values "external-secrets" "onepassword" "secrets") }}
  {{- range (index .Values "external-secrets" "onepassword" "secrets") }}
  {{- if .files }}
  {{- $hasFiles = true }}
  {{- end }}
  {{- end }}
  {{- end }}
  {{- if or .Values.workload.volumes .Values.persistence $hasFiles }}
  volumeMounts:
    {{- include "app.volumeMount" . | nindent 4 }}
  {{- end }}
  {{- if .Values.workload.resources }}
  resources:
    {{- toYaml .Values.workload.resources | nindent 4 }}
  {{- end }}
  {{- if include "app.probeHasContent" (dict "probe" .Values.workload.livenessProbe) }}
  livenessProbe:
    {{- include "app.probe" (dict "probe" .Values.workload.livenessProbe "applicationPort" .Values.workload.applicationPort) | nindent 4 }}
  {{- end }}
  {{- if include "app.probeHasContent" (dict "probe" .Values.workload.readinessProbe) }}
  readinessProbe:
    {{- include "app.probe" (dict "probe" .Values.workload.readinessProbe "applicationPort" .Values.workload.applicationPort) | nindent 4 }}
  {{- end }}
  {{- if include "app.probeHasContent" (dict "probe" .Values.workload.startupProbe) }}
  startupProbe:
    {{- include "app.probe" (dict "probe" .Values.workload.startupProbe "applicationPort" .Values.workload.applicationPort) | nindent 4 }}
  {{- end }}
{{- end }}

{{/*
Render extra (sidecar) containers verbatim as YAML list items.
Usage: {{- include "app.extraContainers" . | nindent 8 }}
*/}}
{{- define "app.extraContainers" -}}
{{- range $i, $container := .Values.workload.extraContainers }}
{{- $_ := required "workload.extraContainers[].name is required" $container.name -}}
{{- if $i }}
{{ toYaml (list $container) }}
{{- else -}}
{{- toYaml (list $container) }}
{{- end -}}
{{- end }}
{{- end }}

{{/*
Render extra init containers verbatim as YAML list items.
Usage: {{- include "app.initContainers" . | nindent 8 }}
*/}}
{{- define "app.initContainers" -}}
{{- range $i, $container := .Values.workload.extraInitContainers }}
{{- $_ := required "workload.extraInitContainers[].name is required" $container.name -}}
{{- if $i }}
{{ toYaml (list $container) }}
{{- else -}}
{{- toYaml (list $container) }}
{{- end -}}
{{- end }}
{{- end }}
