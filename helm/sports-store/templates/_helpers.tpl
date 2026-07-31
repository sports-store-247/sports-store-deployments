{{/*
Return the chart name.
*/}}
{{- define "sports-store.name" -}}
{{- .Chart.Name -}}
{{- end -}}

{{/*
Return a standard full name.
*/}}
{{- define "sports-store.fullname" -}}
{{- .Release.Name -}}
{{- end -}}

{{/*
Common labels.
*/}}
{{- define "sports-store.labels" -}}
app.kubernetes.io/name: {{ include "sports-store.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
{{- end -}}
