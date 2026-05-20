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

{{/*
Init Container for checking if the Yeti API service is up and running.
This is used by background workers to avoid race conditions during database initialization.
*/}}
{{- define "yeti.waitForApi" -}}
- name: wait-for-api
  image: "{{ .Values.config.initDependencyCheck.image }}"
  command: ['sh', '-c']
  args: 
    - |
      # Wait for Yeti API to be listening
      until wget -q -O- http://{{ .Release.Name }}-yeti-api:8000/openapi.json > /dev/null 2>&1; do
        echo "Waiting for Yeti API to be healthy and initialized..."
        sleep 5
      done
      sleep 30
      echo "Yeti API is fully ready."
{{- end }}
