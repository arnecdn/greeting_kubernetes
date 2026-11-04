{{/*
Fullname of the upstream Garage subchart (same logic as garage.fullname, without overrides)
*/}}
{{- define "garage-chart.garageFullname" -}}
{{- if contains "garage" .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-garage" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end }}

{{- define "garage-chart.provisionerName" -}}
{{- printf "%s-provisioner" (include "garage-chart.garageFullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{- define "garage-chart.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Space-separated list of namespaces the Job writes credential Secrets to
*/}}
{{- define "garage-chart.secretNamespaces" -}}
{{- $nsList := list -}}
{{- range .Values.keys -}}
{{- if and .secret .secret.name -}}
{{- $nsList = append $nsList (.secret.namespace | default $.Release.Namespace) -}}
{{- end -}}
{{- end -}}
{{- $nsList | uniq | join " " -}}
{{- end }}

