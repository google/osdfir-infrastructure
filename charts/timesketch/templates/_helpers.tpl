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
{{- if .Values.redis.enabled -}}
{{- $name := include "common.names.fullname" (dict "Chart" (dict "Name" "redis") "Release" .Release "Values" .Values.redis) -}}
{{- $port := .Values.redis.master.service.ports.redis -}}
{{- if .Values.redis.auth.enabled -}}
{{- printf "redis://default:'$REDIS_PASSWORD'@%s-master:%.0f" $name $port -}}
{{- else -}}
{{- printf "redis://%s-master:%.0f" $name $port -}}
{{- end -}}
{{- else -}}
{{ fail "Attempting to use Redis, but the subchart is not enabled. This will lead to misconfiguration" }}
{{- end -}}
{{- end -}}

{{/*
Postgresql subcharts connection url
*/}}
{{- define "timesketch.postgresql.url" -}}
{{- if .Values.postgresql.enabled -}}
{{- $name := include "common.names.fullname" (dict "Chart" (dict "Name" "postgresql") "Release" .Release "Values" .Values.postgresql) -}}
{{- $port := .Values.postgresql.primary.service.ports.postgresql -}}
{{- $username := .Values.postgresql.auth.username -}}
{{- $database := .Values.postgresql.auth.database -}}
{{- printf "postgresql://%s:'$POSTGRES_PASSWORD'@%s:%.0f/%s" $username $name $port $database -}}
{{- else -}}
{{ fail "Attempting to use Postgresql, but the subchart is not enabled. This will lead to misconfiguration" }}
{{- end -}}
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
