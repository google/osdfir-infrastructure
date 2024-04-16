{{/*
Init Container for when a Timesketch pod starts. To prevent duplicate code,
this file has been created which then applies to both the Timesketch Web and
Worker pod upon startup.
*/}}
{{- define "yeti.envs" -}}
- name: YETI_REDIS_HOST
  value: {{ include "yeti.redis.url" . }}
- name: YETI_REDIS_PORT
  value: "{{ .Values.redis.master.service.ports.redis }}"
- name: YETI_REDIS_DATABASE
  value: "0"
- name: YETI_ARANGODB_HOST
  value: {{ include "yeti.fullname" . }}-arangodb
- name: YETI_ARANGODB_PORT
  value: {{ .Values.arangodb.service.port | quote }}
- name: YETI_ARANGODB_DATABASE
  value: yeti
- name: YETI_ARANGODB_USERNAME
  value: root
- name: YETI_AUTH_SECRET_KEY
  value: {{ randAlphaNum 32 | quote }}
- name: YETI_AUTH_ALGORITHM
  value: HS256
- name: YETI_AUTH_ACCESS_TOKEN_EXPIRE_MINUTES
  value: "30"
- name: YETI_AUTH_ENABLED
  value: "True"
- name: YETI_SYSTEM_PLUGINS_PATH
  value: "./plugins"
- name: YETI_USER_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "yeti.fullname" . }}-secret 
      key: yeti-user
- name: YETI_ARANGODB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "yeti.fullname" . }}-secret 
      key: yeti-arangodb
- name: YETI_API_KEY
  valueFrom:
    secretKeyRef:
      name: {{ include "yeti.fullname" . }}-secret 
      key: yeti-api
{{- if .Values.global.timesketch.enabled }}
- name: YETI_TIMESKETCH_ENDPOINT
  value: {{ printf "http://%s-timesketch:%.0f" .Release.Name .Values.global.timesketch.servicePort | quote }}
- name: YETI_TIMESKETCH_USERNAME
  value: timesketch
- name: YETI_TIMESKETCH_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ printf "%s-timesketch-secret" .Release.Name | quote }}
      key: timesketch-user
{{- end }}
{{- end }}