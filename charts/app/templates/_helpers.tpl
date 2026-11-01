
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
Validated workload type: "Deployment" (default) or "StatefulSet".
Fails on anything else (e.g. a lowercase typo) instead of rendering nothing.
*/}}
{{- define "app.workloadType" -}}
{{- $type := .Values.workload.type | default "Deployment" -}}
{{- if not (has $type (list "Deployment" "StatefulSet")) -}}
{{- fail (printf "workload.type must be \"Deployment\" or \"StatefulSet\" (got %q)" $type) -}}
{{- end -}}
{{- $type -}}
{{- end }}

{{/*
Main container image reference "<repository>:<tag>".
YAML turns an unquoted tag like 1.10 into the number 1.1, which silently
pulls the wrong image, so a non-string tag containing "." fails with a hint.
Whole-number tags (e.g. 15) are safe and are converted to text.
*/}}
{{- define "app.image" -}}
{{- $tag := .Values.workload.image.tag -}}
{{- if not (kindIs "string" $tag) -}}
{{- if contains "." (toString $tag) -}}
{{- fail (printf "workload.image.tag was read as the number %v (YAML drops trailing zeros, so 1.10 becomes 1.1). Quote the tag exactly as published, e.g. tag: \"1.10\"" $tag) -}}
{{- end -}}
{{- $tag = toString $tag -}}
{{- end -}}
{{- required "workload.image.repository is required" .Values.workload.image.repository -}}:{{- required "workload.image.tag is required" $tag -}}
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
Returns "true" when external-secrets AND onepassword are both enabled (i.e.
the subchart actually renders the ExternalSecrets) and any onepassword.secrets
entry defines the given field
("envVars" or "files"), otherwise "". All entries of a kind are merged into a
single ExternalSecret by the external-secrets chart, so the app mounts or
references each kind at most once.
Usage: include "app.onepassword.has" (dict "root" $ "field" "files")
*/}}
{{- define "app.onepassword.has" -}}
{{- $es := index .root.Values "external-secrets" | default dict -}}
{{- $op := $es.onepassword | default dict -}}
{{- $found := false -}}
{{- if and $es.enabled $op.enabled -}}
{{- range $op.secrets -}}
{{- if index . $.field -}}{{- $found = true -}}{{- end -}}
{{- end -}}
{{- end -}}
{{- if $found -}}true{{- end -}}
{{- end }}

{{/*
Merged annotations for one persistence entry, as YAML (or "" when none).
Used by both the Deployment PVCs and the StatefulSet volumeClaimTemplates so
they can't drift apart. For storageClassName "opendrive" the rclone defaults
come first, then rclone.annotations, then the entry's own annotations (which
win on conflicts).
Usage: include "app.pvcAnnotations" (dict "root" $ "pvc" .)
*/}}
{{- define "app.pvcAnnotations" -}}
{{- $pvc := .pvc -}}
{{- $out := dict -}}
{{- if eq ($pvc.storageClassName | default "") "opendrive" -}}
{{- $rclone := $pvc.rclone | default dict -}}
{{- $_ := set $out "csi-rclone/storage-path" ($rclone.storagePath | default (include "helm-helpers.fullname" .root)) -}}
{{- $_ := set $out "csi-rclone/umask" ($rclone.umask | default "022" | toString) -}}
{{- $out = merge (deepCopy ($rclone.annotations | default dict)) $out -}}
{{- end -}}
{{- $out = merge (deepCopy ($pvc.annotations | default dict)) $out -}}
{{- if $out -}}
{{- toYaml $out -}}
{{- end -}}
{{- end }}

{{/*
Annotations for the Deployment/StatefulSet object: workload.annotations plus,
when workload.reloadOnSecretChange is on, the Stakater Reloader annotation
listing the onepassword secrets so pods restart when they change.
Returns YAML or "".
*/}}
{{- define "app.workloadAnnotations" -}}
{{- $out := deepCopy (.Values.workload.annotations | default dict) -}}
{{- if .Values.workload.reloadOnSecretChange -}}
{{- $names := list -}}
{{- if include "app.onepassword.has" (dict "root" . "field" "envVars") -}}
{{- $names = append $names (printf "%s-onepassword-env" (include "helm-helpers.fullname" .)) -}}
{{- end -}}
{{- if include "app.onepassword.has" (dict "root" . "field" "files") -}}
{{- $names = append $names (printf "%s-onepassword-files" (include "helm-helpers.fullname" .)) -}}
{{- end -}}
{{- if $names -}}
{{- $_ := set $out "secret.reloader.stakater.com/reload" (join "," $names) -}}
{{- end -}}
{{- end -}}
{{- if $out -}}
{{- toYaml $out -}}
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
{{- if include "app.onepassword.has" (dict "root" . "field" "files") }}
- name: {{ printf "%s-onepassword-files" (include "helm-helpers.fullname" .) }}
  mountPath: /etc/secrets/onepassword
  readOnly: true
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
{{- /* StatefulSets get these volumes from volumeClaimTemplates instead */ -}}
{{- if eq (include "app.workloadType" .) "Deployment" }}
{{- range .Values.persistence }}
- name: {{ .name }}
  persistentVolumeClaim:
    claimName: {{ printf "%s-%s" (include "helm-helpers.fullname" $) .name }}
{{- end }}
{{- end }}
{{- if include "app.onepassword.has" (dict "root" . "field" "files") }}
- name: {{ printf "%s-onepassword-files" (include "helm-helpers.fullname" .) }}
  secret:
    secretName: {{ printf "%s-onepassword-files" (include "helm-helpers.fullname" .) }}
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
  image: {{ include "app.image" . | quote }}
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
  {{- if or .Values.workload.environment .Values.workload.extraEnv }}
  env:
    {{- range $key, $value := .Values.workload.environment }}
    - name: {{ $key }}
      value: {{ $value | quote }}
    {{- end }}
    {{- with .Values.workload.extraEnv }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  {{- end }}
  {{- $onepasswordEnv := include "app.onepassword.has" (dict "root" . "field" "envVars") }}
  {{- if or $onepasswordEnv .Values.workload.extraEnvFrom }}
  envFrom:
    {{- if $onepasswordEnv }}
    - secretRef:
        name: {{ printf "%s-onepassword-env" (include "helm-helpers.fullname" .) }}
    {{- end }}
    {{- with .Values.workload.extraEnvFrom }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  {{- end }}
  {{- if or .Values.workload.volumes .Values.persistence (include "app.onepassword.has" (dict "root" . "field" "files")) }}
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
Fail if two containers in the pod share a name. Kubernetes requires names to
be unique across the main container, sidecars and init containers, but only
rejects duplicates at install time.
*/}}
{{- define "app.validateContainerNames" -}}
{{- $seen := dict (include "helm-helpers.appName" .) "the main container" -}}
{{- range $kind, $list := dict "workload.extraContainers" .Values.workload.extraContainers "workload.extraInitContainers" .Values.workload.extraInitContainers -}}
{{- range $list -}}
{{- if and .name (hasKey $seen .name) -}}
{{- fail (printf "%s: container name %q is already used by %s; container names must be unique in the pod" $kind .name (get $seen .name)) -}}
{{- end -}}
{{- if .name -}}{{- $_ := set $seen .name $kind -}}{{- end -}}
{{- end -}}
{{- end -}}
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
