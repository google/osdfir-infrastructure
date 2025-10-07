{{/*
Common labels
*/}}
{{- define "yeti.labels" -}}
{{ include "yeti.selectorLabels" . }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }} 
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "yeti.selectorLabels" -}}
app.kubernetes.io/name: yeti
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
