{{/*
Check if tag contains specific platform suffix and if not set based on kube platform
*/}}
{{- define "platform" -}}
    {{- printf "" }}
{{- end -}}

{{/*
Check if tag contains specific platform suffix and if not set based on kube platform
*/}}
{{- define "helperplatform" -}}
    {{- if (eq "x86_64" .Values.arch) }}
       {{- printf "%s" "amd64" }}
    {{- else -}}
       {{- printf "%s" .Values.arch }}
    {{- end -}}
{{- end -}}

{{/*
Return arch based on kube platform
*/}}
{{- define "arch" -}}
    {{- if (eq "x86_64" .Values.arch) }}
       {{- printf "%s" "amd64" }}
    {{- else -}}
       {{- printf "%s" .Values.arch }}
    {{- end -}}
{{- end -}}


