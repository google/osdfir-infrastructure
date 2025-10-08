{{/*
Init Container for checking for the Postgres and Redis service prior to starting
the OpenRelik API, Mediator, and Metrics Pods.
*/}}
{{- define "openrelik.initContainer" -}}
- name: wait-for-deps
  image: "{{ .Values.config.initDependencyCheck.image }}"
  command: ['sh', '-c']
  args: 
    - |
      # Wait for Postgres
      until nslookup {{ .Release.Name }}-openrelik-postgres; do echo waiting for Postgres; sleep 30; done
      echo "Postgres service is discoverable."

      # Wait for Redis
      until nslookup {{ .Release.Name }}-openrelik-redis; do echo waiting for Redis; sleep 30; done
      echo "Redis service is discoverable."
{{- end }}
