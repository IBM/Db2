{{/*
Check if tag contains specific platform suffix and if not set based on kube platform
*/}}
{{- define "platform" -}}
  {{- printf "%s" "" }}
{{- end -}}

{{/*
Check if tag contains specific platform suffix and if not set based on kube platform
*/}}
{{- define "helperplatform" -}}
{{- if not .Values.arch }}
  {{- if (eq "linux/amd64" .Capabilities.KubeVersion.Platform) }}
    {{- printf "%s" "amd64" }}
  {{- end -}}
  {{- if (eq "linux/ppc64le" .Capabilities.KubeVersion.Platform) }}
    {{- printf "%s" "ppc64le" }}
  {{- end -}}
{{- else -}}
    {{- if (eq "x86_64" .Values.arch) }}
       {{- printf "%s" "amd64" }}
    {{- else -}}
       {{- printf "%s" .Values.arch }}
    {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Return arch based on kube platform
*/}}
{{- define "arch" -}}
  {{- if (eq "linux/amd64" .Capabilities.KubeVersion.Platform) }}
    {{- printf "%s" "amd64" }}
  {{- end -}}
  {{- if (eq "linux/ppc64le" .Capabilities.KubeVersion.Platform) }}
    {{- printf "%s" "ppc64le" }}
  {{- end -}}
{{- end -}}


