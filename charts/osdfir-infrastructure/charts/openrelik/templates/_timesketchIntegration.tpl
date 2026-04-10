{{/*
Init Container for checking for the Postgres and Redis service prior to starting
the OpenRelik API, Mediator, and Metrics Pods.
*/}}
{{- define "timesketch.envVariables" -}}
{{- if .Values.global.timesketch.enabled -}}
- name: TIMESKETCH_SERVER_URL
  value: {{ printf "http://%s-timesketch:5000" $.Release.Name | quote }}
- name: TIMESKETCH_USERNAME
  value: timesketch
- name: TIMESKETCH_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ printf "%s-timesketch-secret" $.Release.Name | quote }}
      key: timesketch-user
{{- else if and .Values.global.timesketch.automationUserSecretName .Values.global.timesketch.namespace -}}
- name: TIMESKETCH_SERVER_URL
  value: {{ printf "http://%s-timesketch.%s:5000" .Release.Name .Values.global.timesketch.namespace | quote }}
- name: TIMESKETCH_USERNAME
  valueFrom:
    secretKeyRef:
      name: {{ .Values.global.timesketch.automationUserSecretName }}
      key: timesketch-user
- name: TIMESKETCH_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .Values.global.timesketch.automationUserSecretName }}
      key: timesketch-password
{{- end }}
{{- end }}