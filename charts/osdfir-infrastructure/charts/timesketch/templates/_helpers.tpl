{{/*
Common labels
*/}}
{{- define "timesketch.labels" -}}
{{ include "timesketch.selectorLabels" . }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
date: "{{ now | htmlDate }}"
{{- end }}

{{/*
Selector labels
*/}}
{{- define "timesketch.selectorLabels" -}}
app.kubernetes.io/name: timesketch
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Redis connection url
*/}}
{{- define "timesketch.redis.url" -}}
{{- $name := printf "%s-timesketch-redis" (.Release.Name) -}}
{{- printf "redis://default:'$REDIS_PASSWORD'@%s:6379" $name -}}
{{- end -}}

{{/*
Postgresql connection url
*/}}
{{- define "timesketch.postgresql.url" -}}
{{- $name := printf "%s-timesketch-postgres" (.Release.Name) -}}
{{- printf "postgresql://postgres:'$POSTGRES_PASSWORD'@%s:5432/timesketch" $name -}}
{{- end -}}

{{/*
Opensearch host name
*/}}
{{- define "timesketch.opensearch.host" -}}
{{- printf "%s-opensearch-cluster" .Release.Name -}}
{{- end -}}

{{/*
Opensearch endpoints
*/}}
{{- define "timesketch.opensearch.endpoints" -}}
{{- $replicas := int (toString (.Values.opensearch.replicas)) }}
{{- $uname := printf "%s-opensearch-cluster" (.Release.Name) }}
  {{- range $i, $e := untilStep 0 $replicas 1 -}}
{{ $uname }}-{{ $i }},
  {{- end -}}
{{- end -}}

{{- define "timesketch.oidc.authenticatedemails" -}}
{{- if .Values.config.oidc.authenticatedEmailsFile.existingSecret -}}
{{- .Values.config.oidc.authenticatedEmailsFile.existingSecret -}}
{{- else -}}
{{- printf "%s-timesketch-access-list" (.Release.Name) -}}
{{- end -}}
{{- end -}}
