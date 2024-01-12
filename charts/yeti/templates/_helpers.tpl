{{/*
Expand the name of the chart.
*/}}
{{- define "yeti.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "yeti.fullname" -}}
{{- if contains .Chart.Name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name "yeti" | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "yeti.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Return the proper persistence volume claim name
*/}}
{{- define "yeti.pvc.name" -}}
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
{{- define "yeti.storage.class" -}}
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
Common labels
*/}}
{{- define "yeti.labels" -}}
helm.sh/chart: {{ include "yeti.chart" . }}
{{ include "yeti.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
date: "{{ now | htmlDate }}"
{{- end }}

{{/*
Selector labels
*/}}
{{- define "yeti.selectorLabels" -}}
app.kubernetes.io/name: {{ include "yeti.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "yeti.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "yeti.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
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

{{/*
Yeti service port
*/}}
{{- define "yeti.service.port" -}}
{{- if .Values.global.yeti.servicePort -}}
{{ .Values.global.yeti.servicePort }}
{{- else -}}
{{ .Values.service.port }}
{{- end -}}
{{- end -}}