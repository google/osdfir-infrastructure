{{/*
Common labels
*/}}
{{- define "hashr.labels" -}}
{{ include "hashr.selectorLabels" . }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "hashr.selectorLabels" -}}
app.kubernetes.io/name: hashr
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
