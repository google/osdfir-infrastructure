{{/*
Init Container for when a OpenRelik server starts. Required for setting up
OIDC when enabled due to the changes having to be in settings.toml
*/}}
{{- define "openrelik.initContainer" -}}
- name: init-openrelik
  image: ubuntu
  command: ['sh', '-c', '/init/init-openrelik.sh']
  {{- if and .Values.config.oidc.enabled .Values.config.oidc.existingSecret }} 
  env:
    - name: OIDC_CLIENT_ID
      valueFrom:
        secretKeyRef:
          name: {{ .Values.config.oidc.existingSecret | quote }}
          key: "client-id"
    - name: OIDC_CLIENT_SECRET
      valueFrom:
        secretKeyRef:
          name: {{ .Values.config.oidc.existingSecret | quote }}
          key: "client-secret"
  {{- end }}
  volumeMounts:
    - mountPath: /tmp/openrelik/settings.toml
      subPath: settings.toml
      name: settings-config
    - mountPath: /init/
      name: init-oidc
    - mountPath: /etc/openrelik
      name: openrelik-configs-dir
    {{- if .Values.config.oidc.authenticatedEmailsFile.enabled }}
    - name: authenticated-emails
      mountPath: /init/authenticated-emails
      readOnly: true
    {{- end }}
{{- end }}
