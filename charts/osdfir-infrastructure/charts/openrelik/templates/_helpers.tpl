{{/*
Common labels
*/}}
{{- define "openrelik.labels" -}}
{{ include "openrelik.selectorLabels" . }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
date: "{{ now | htmlDate }}"
{{- end }}

{{/*
Selector labels
*/}}
{{- define "openrelik.selectorLabels" -}}
app.kubernetes.io/name: openrelik
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "openrelik.oidc.authenticatedemails" -}}
{{- if .Values.config.oidc.authenticatedEmailsFile.existingSecret -}}
{{- .Values.config.oidc.authenticatedEmailsFile.existingSecret -}}
{{- else -}}
{{- printf "%s-openrelik-access-list" (.Release.Name) -}}
{{- end -}}
{{- end -}}
