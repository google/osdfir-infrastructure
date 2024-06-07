
{{/*
Return the proper persistence volume claim name
*/}}
{{- define "osdfir.pvc.name" -}}
{{- $pvcName := .Values.persistence.name -}}
{{- if .Values.global -}}
    {{- if .Values.global.existingPVC -}}
        {{- $pvcName = .Values.global.existingPVC -}}
    {{- end -}}
{{- printf "%s-%s" $pvcName "claim" }}
{{- end -}}
{{- end -}}

{{/*
Return the proper Storage Class
*/}}
{{- define "osdfir.storage.class" -}}
{{- $storageClass := .Values.persistence.storageClass -}}
{{- if .Values.global -}}
    {{- if .Values.global.storageClass -}}
        {{- $storageClass = .Values.global.storageClass -}}
    {{- end -}}
{{- end -}}
{{- if $storageClass -}}
  {{- if (eq "-" $storageClass) -}}
      {{- printf "storageClassName: \"\"" -}}
  {{- else }}
      {{- printf "storageClassName: %s" $storageClass -}}
  {{- end -}}
{{- end -}}
{{- end -}}