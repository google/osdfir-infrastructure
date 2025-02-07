{{/*
Init Container for when a Timesketch pod starts. To prevent duplicate code,
this file has been created which then applies to both the Timesketch Web and
Worker pod upon startup.
*/}}
{{- define "yeti.envs" -}}
- name: YETI_REDIS_HOST
  value: "{{ .Release.Name }}-yeti-redis"
- name: YETI_REDIS_PORT
  value: "6379"
- name: YETI_REDIS_DATABASE
  value: "0"
- name: YETI_ARANGODB_HOST
  value: {{ .Release.Name }}-yeti-arangodb
- name: YETI_ARANGODB_PORT
  value: "8529"
- name: YETI_ARANGODB_DATABASE
  value: yeti
- name: YETI_ARANGODB_USERNAME
  value: root
- name: YETI_AUTH_SECRET_KEY
  value: {{ randAlphaNum 32 | quote }}
- name: YETI_AUTH_ALGORITHM
  value: HS256
- name: YETI_AUTH_ACCESS_TOKEN_EXPIRE_MINUTES
  value: "10000"
- name: YETI_AUTH_ENABLED
  value: "True"
{{- if and .Values.config.oidc.enabled .Values.config.oidc.existingSecret }}
- name: YETI_AUTH_MODULE
  value: "oidc"
- name: YETI_AUTH_OIDC_DISCOVERY_URL
  value: "https://accounts.google.com/.well-known/openid-configuration"
- name: YETI_AUTH_OIDC_CLIENT_ID
  valueFrom:
    secretKeyRef:
      name: {{ .Values.config.oidc.existingSecret | quote }}
      key: "client-id"
- name: YETI_AUTH_OIDC_CLIENT_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ .Values.config.oidc.existingSecret | quote }}
      key: "client-secret"
{{- if .Values.ingress.host }}
- name: YETI_SYSTEM_WEBROOT
  value: {{ printf "https://%s" .Values.ingress.host | quote }}
{{- end }}
{{- end }}
- name: YETI_SYSTEM_PLUGINS_PATH
  value: "./plugins"
- name: YETI_USER_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-yeti-secret 
      key: yeti-user
- name: YETI_ARANGODB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-yeti-secret 
      key: yeti-arangodb
- name: YETI_API_KEY
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-yeti-secret 
      key: yeti-api
{{- if .Values.global.timesketch.enabled }}
- name: YETI_TIMESKETCH_ENDPOINT
  value: {{ printf "http://%s-timesketch:5000" .Release.Name | quote }}
- name: YETI_TIMESKETCH_USERNAME
  value: timesketch
- name: YETI_TIMESKETCH_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ printf "%s-timesketch-secret" .Release.Name | quote }}
      key: timesketch-user
{{- end }}
{{- end }}