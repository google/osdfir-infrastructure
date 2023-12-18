{{/*
Expand the name of the chart.
*/}}
{{- define "timesketch.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "timesketch.fullname" -}}
{{- if contains .Chart.Name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name "timesketch" | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "timesketch.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Return the proper persistence volume claim name
*/}}
{{- define "timesketch.pvc.name" -}}
{{- $pvcName := .Values.persistence.name -}}
{{- if .Values.global -}}
    {{- if .Values.global.existingPVC -}}
        {{- $pvcName = .Values.global.existingPVC -}}
    {{- end -}}
{{- printf "%s-%s" $pvcName "claim" }}
{{- end -}}
{{- end -}}

{{/*
Return the proper Storage Class
*/}}
{{- define "timesketch.storage.class" -}}
{{- $storageClass := .Values.persistence.storageClass -}}
{{- if .Values.global -}}
    {{- if .Values.global.storageClass -}}
        {{- $storageClass = .Values.global.storageClass -}}
    {{- end -}}
{{- end -}}
{{- if $storageClass -}}
  {{- if (eq "-" $storageClass) -}}
      {{- printf "storageClassName: \"\"" -}}
  {{- else }}
      {{- printf "storageClassName: %s" $storageClass -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create the upload path.
*/}}
{{- define "timesketch.uploadPath" -}}
{{- $pvcName := .Values.persistence.name -}}
{{- if .Values.global -}}
    {{- if .Values.global.existingPVC -}}
        {{- $pvcName = .Values.global.existingPVC -}}
    {{- end -}}
{{- printf "/mnt/%s/upload" $pvcName }}
{{- end }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "timesketch.labels" -}}
helm.sh/chart: {{ include "timesketch.chart" . }}
{{ include "timesketch.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
date: "{{ now | htmlDate }}"
{{- end }}

{{/*
Selector labels
*/}}
{{- define "timesketch.selectorLabels" -}}
app.kubernetes.io/name: {{ include "timesketch.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "timesketch.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "timesketch.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
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
Opensearch subcharts host name
*/}}
{{- define "timesketch.opensearch.host" -}}
{{- if .Values.opensearch.enabled -}}
{{- printf "%s" .Values.opensearch.masterService -}}
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

{{/*
Timesketch service port
*/}}
{{- define "timesketch.service.port" -}}
{{- if .Values.global.timesketch.servicePort -}}
{{ .Values.global.timesketch.servicePort }}
{{- else -}}
{{ .Values.service.port }}
{{- end -}}
{{- end -}}