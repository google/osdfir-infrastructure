{{/*
Init Container for when a OpenRelik worker requires the nbd module loaded into
the underlying node to allow for processing of qcow2 disk images.
*/}}
{{- define "openrelik.initContainerWorker" -}}
- name: init-nbd-module
  image: {{ .Values.config.initWorkerNbd.image }}
  command: ['sh']
  args:
    - "-c"
    - |
      if ! lsmod | grep -q "^nbd "; then
        echo "nbd module not loaded. Attempting to load..."
        if modprobe nbd; then
          echo "nbd module loaded successfully."
        else
          echo "Error: Failed to load nbd module." >&2
          exit 1
        fi
      else
        echo "nbd module already loaded."
      fi
  securityContext:
    privileged: true
    runAsUser: 0
  volumeMounts:
    - mountPath: /lib/modules
      name: modules
      readOnly: true
{{- end }}
