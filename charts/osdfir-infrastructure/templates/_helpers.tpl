
{{/*
Expand the name of the chart.
*/}}
{{- define "osdfir.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "osdfir.fullname" -}}
{{- if contains .Chart.Name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name "osdfir" | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "osdfir.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "osdfir.labels" -}}
helm.sh/chart: {{ include "osdfir.chart" . }}
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
app.kubernetes.io/name: {{ include "osdfir.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Return the proper persistence volume claim name
*/}}
{{- define "osdfir.pvc.name" -}}
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
{{- define "osdfir.storage.class" -}}
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