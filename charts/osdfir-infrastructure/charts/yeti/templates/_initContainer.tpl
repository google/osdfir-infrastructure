{{/*
Init Container for checking for the Redis and ArangoDB service prior to starting
the Yeti Pods.
*/}}
{{- define "yeti.initContainer" -}}
- name: wait-for-deps
  image: "{{ .Values.config.initDependencyCheck.image }}"
  command: ['sh', '-c']
  args: 
    - |
      # Wait for Redis
      until nslookup {{ .Release.Name }}-yeti-redis; do echo waiting for Redis; sleep 30; done
      echo "Redis service is discoverable."

      # Wait for ArangoDB
      until nslookup {{ .Release.Name }}-yeti-arangodb; do echo waiting for ArangoDB; sleep 30; done
      echo "ArangoDB service is discoverable."
{{- end }}
