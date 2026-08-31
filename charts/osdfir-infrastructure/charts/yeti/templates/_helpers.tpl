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

Agents need a model provider and Yeti API credentials. Asking for them without
either is a mistake worth stopping the install for: the pod would start and
then be unable to answer, which is harder to diagnose after the fact than a
message naming the secret that is missing.

Defined once here because the same answer decides three things -- the
StatefulSet, its Service, and whether the Yeti API is told the feature exists --
and those must not be able to disagree.

Emits a non-empty string when true, so callers test it with `if`.
*/}}
{{- define "yeti.agentsEnabled" -}}
{{- if and .Values.agents .Values.agents.enabled -}}
{{- if and (not .Values.agents.googleApiKeySecret) (ne .Values.agents.llmProvider "ollama") -}}
{{- fail (printf "\n\nagents.enabled is true but agents.googleApiKeySecret is not set.\nThe Yeti Agents service reads GOOGLE_API_KEY at startup and cannot run without it.\n\nCreate the secret and pass its name:\n  kubectl create secret generic yeti-google-api-secret \\\n    --namespace %s --from-literal=google-api-key=$GOOGLE_API_KEY\n  helm upgrade ... --set agents.googleApiKeySecret=yeti-google-api-secret\n\nAlternatively set agents.llmProvider=ollama to use a local model, or\nagents.enabled=false to deploy Yeti without the agents service.\n" .Release.Namespace) -}}
{{- end -}}
{{- if not .Values.agents.yetiApiKeySecret -}}
{{- fail (printf "\n\nagents.enabled is true but agents.yetiApiKeySecret is not set.\nThe agents reach Yeti over its API; without these credentials they start but\nevery tool call fails.\n\nCreate the secret and pass its name:\n  kubectl create secret generic yeti-api-secret \\\n    --namespace %s --from-literal=yeti-api=$YETI_API_KEY\n  helm upgrade ... --set agents.yetiApiKeySecret=yeti-api-secret\n\nAlternatively set agents.enabled=false to deploy Yeti without the agents service.\n" .Release.Namespace) -}}
{{- end -}}
true
{{- end -}}
{{- end }}
