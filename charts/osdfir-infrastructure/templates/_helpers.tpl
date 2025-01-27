{{/*
Common labels
*/}}
{{- define "osdfir.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
{{ include "osdfir.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
date: "{{ now | htmlDate }}"
{{- end }}

{{/*
Selector labels
*/}}
{{- define "osdfir.selectorLabels" -}}
app.kubernetes.io/name: osdfir
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}