{{/*
Common labels
*/}}
{{- define "yeti.labels" -}}
{{ include "yeti.selectorLabels" . }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }} 
app.kubernetes.io/managed-by: {{ .Release.Service }}
date: "{{ now | htmlDate }}"
{{- end }}

{{/*
Selector labels
*/}}
{{- define "yeti.selectorLabels" -}}
app.kubernetes.io/name: yeti
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Redis subcharts connection url
*/}}
{{- define "yeti.redis.url" -}}
{{- if .Values.redis.enabled -}}
{{- $name := include "common.names.fullname" (dict "Chart" (dict "Name" "redis") "Release" .Release "Values" .Values.redis) -}}
{{- $port := .Values.redis.master.service.ports.redis -}}
{{- printf "%s-master" $name -}}
{{- else -}}
{{ fail "Attempting to use Redis, but the subchart is not enabled. This will lead to misconfiguration" }}
{{- end -}}
{{- end -}}
