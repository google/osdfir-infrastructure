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
Redis subcharts connection url
*/}}
{{- define "timesketch.redis.url" -}}
{{- $name := printf "%s-timesketch-redis" (.Release.Name) -}}
{{- printf "redis://default:'$REDIS_PASSWORD'@%s:6379" $name -}}
{{- end -}}

{{/*
Postgresql subcharts connection url
*/}}
{{- define "timesketch.postgresql.url" -}}
{{- $name := printf "%s-timesketch-postgres" (.Release.Name) -}}
{{- printf "postgresql://postgres:'$POSTGRES_PASSWORD'@%s:5432/timesketch" $name -}}
{{- end -}}

{{/*
Override Opensearch Subchart "opensearch.uname" helper function to allow for
multiple instances using the Release Name.
*/}}
{{- define "opensearch.uname" -}}
{{- printf "%s-%s" .Release.Name .Values.masterService -}}
{{- end -}}

{{/*
Opensearch subcharts host name
*/}}
{{- define "timesketch.opensearch.host" -}}
{{- if .Values.opensearch.enabled -}}
{{- printf "%s-%s" .Release.Name .Values.opensearch.masterService -}}
{{- else -}}
{{ fail "Attempting to use Opensearch, but the subchart is not enabled. This will lead to misconfiguration" }}
{{- end -}}
{{- end -}}

{{/*
Opensearch subcharts port
*/}}
{{- define "timesketch.opensearch.port" -}}
{{- if .Values.opensearch.enabled -}}
{{- printf "%.0f" .Values.opensearch.httpPort -}}
{{- else -}}
{{ printf "Attempting to use Opensearch, but the subchart is not enabled. This will lead to misconfiguration" }}
{{- end -}}
{{- end -}}

{{- define "timesketch.oidc.authenticatedemails" -}}
{{- if .Values.config.oidc.authenticatedEmailsFile.existingSecret -}}
{{- .Values.config.oidc.authenticatedEmailsFile.existingSecret -}}
{{- else -}}
{{- printf "%s-timesketch-access-list" (.Release.Name) -}}
{{- end -}}
{{- end -}}
