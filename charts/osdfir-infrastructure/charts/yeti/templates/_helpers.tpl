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

{{/*
Whether the Yeti Agents service can actually run.

Agents need a model provider and Yeti API credentials; without either they
start but cannot answer, so the workload is not rendered rather than deployed
in a state that can only fail. Defined once here because the same condition
decides three things -- the StatefulSet, its Service, and whether the Yeti API
is told the feature exists -- and those must not be able to disagree.

Emits a non-empty string when true, so callers test it with `if`.
*/}}
{{- define "yeti.agentsEnabled" -}}
{{- if and .Values.agents .Values.agents.enabled .Values.global.yeti.apiKeySecret -}}
{{- if or .Values.agents.googleApiKeySecret (eq .Values.agents.llmProvider "ollama") -}}
true
{{- end -}}
{{- end -}}
{{- end }}
