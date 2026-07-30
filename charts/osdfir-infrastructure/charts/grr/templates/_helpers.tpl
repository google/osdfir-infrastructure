{{/*
Expand the name of the chart.
*/}}
{{- define "grr.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "grr.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "grr.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "grr.labels" -}}
helm.sh/chart: {{ include "grr.chart" . }}
{{ include "grr.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "grr.selectorLabels" -}}
app.kubernetes.io/name: {{ include "grr.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "grr.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "grr.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Resolve the address embedded in Fleetspeak client installers.
*/}}
{{- define "grr.clientBuilderAddress" -}}
{{- $clientBuilder := .Values.clientBuilder | default dict -}}
{{- $address := get $clientBuilder "address" | default "" -}}
{{- if $address -}}
{{- $address -}}
{{- else if or (eq .Values.fleetspeak.frontend.expose "internal") (eq .Values.fleetspeak.frontend.expose "external") -}}
{{- default "10.0.0.2" .Values.fleetspeak.frontend.address -}}
{{- else -}}
{{- $frontend := "" -}}
{{- $lookupResult := lookup "v1" "Node" "" "" | default dict -}}
{{- range (get $lookupResult "items" | default list) -}}
{{- range (get (get . "status" | default dict) "addresses" | default list) -}}
{{- if and (not $frontend) (eq (get . "type") "InternalIP") -}}
{{- $frontend = get . "address" -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- default "10.0.0.2" $frontend -}}
{{- end -}}
{{- end }}

{{/*
Resolve the port embedded in Fleetspeak client installers.
*/}}
{{- define "grr.clientBuilderPort" -}}
{{- $clientBuilder := .Values.clientBuilder | default dict -}}
{{- default .Values.fleetspeak.frontend.listenPort (get $clientBuilder "port") -}}
{{- end }}

{{/*
Hash the inputs that determine the Fleetspeak frontend certificate.
*/}}
{{- define "grr.fleetspeakCertificateHash" -}}
{{- $frontend := .Values.fleetspeak.frontend | default dict -}}
{{- printf "%v|%s|%s|%s|%s|%s" .Values.fleetspeak.generateCert .Values.fleetspeak.subjectCommonName (include "grr.clientBuilderAddress" .) (include "grr.clientBuilderPort" .) (get $frontend "cert" | default "") (get $frontend "key" | default "") | sha256sum -}}
{{- end }}

{{/*
Hash the inputs that determine a GRR client build.
*/}}
{{- define "grr.clientBuilderHash" -}}
{{- $clientBuilder := .Values.clientBuilder | default dict -}}
{{- printf "%s|%s|%s|%s|%s|%s|%s|%s" (include "grr.fleetspeakCertificateHash" .) (get $clientBuilder "trustedCert" | default "") .Values.grr.version (.Values.grr.daemon.image | default "") .Values.initContainer.image .Values.initContainer.kanikoImage .Chart.Version .Release.Name | sha256sum -}}
{{- end }}
