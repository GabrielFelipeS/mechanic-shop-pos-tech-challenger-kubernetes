variable "newrelic_account_id" {
  description = "ID da conta New Relic."
  type        = number
}

variable "newrelic_api_key" {
  description = "User API key do New Relic (NRAK-...). Em CI vem do secret NEW_RELIC_API_KEY."
  type        = string
  sensitive   = true
}

variable "newrelic_region" {
  description = "Regiao da conta New Relic: US ou EU."
  type        = string
  default     = "US"

  validation {
    condition     = contains(["US", "EU"], var.newrelic_region)
    error_message = "newrelic_region deve ser US ou EU."
  }
}

# ---------------------------------------------------------------------------
# Identidade do ambiente monitorado
#
# Estes tres valores sao o contrato entre esta stack e as infras (infra/kind,
# infra/aws, infra/aws-academy): as NRQL abaixo filtram exatamente por eles.
# Nao tem default de proposito -- um default silencioso e o que fazia o
# dashboard consultar um appName/clusterName que nenhuma infra reportava.
# Use os arquivos em envs/*.tfvars, gerados a partir do output
# "observability_tfvars" de cada infra.
# ---------------------------------------------------------------------------

variable "app_name" {
  description = <<-EOT
    Nome da aplicacao no APM. Precisa ser identico ao NEW_RELIC_APP_NAME do
    ambiente (var.newrelic_app_name na infra correspondente).
  EOT
  type        = string
}

variable "cluster_name" {
  description = <<-EOT
    Nome do cluster Kubernetes reportado pelo nri-bundle (global.cluster).
    Precisa ser identico ao output "newrelic_cluster_name" da infra.
  EOT
  type        = string
}

variable "namespace" {
  description = "Namespace Kubernetes da aplicacao."
  type        = string
  default     = "mechanic-shop"
}

variable "workload_name" {
  description = <<-EOT
    Nome do Deployment/container da API no cluster. Usado nos filtros de
    K8sDeploymentSample, K8sContainerSample e K8sPodSample.
  EOT
  type        = string
  default     = "mechanic-shop-backend"
}

variable "health_check_url" {
  description = "URL publica do healthcheck monitorada pelo Synthetics."
  type        = string
}

variable "synthetics_locations" {
  description = "Localidades publicas do monitor Synthetics."
  type        = list(string)
  default     = ["AWS_US_EAST_1", "AWS_SA_EAST_1"]
}

variable "alert_email" {
  description = "E-mail que recebe as notificacoes dos alertas."
  type        = string
}

# ---------------------------------------------------------------------------
# Limiares dos alertas
# ---------------------------------------------------------------------------

variable "api_latency_threshold_seconds" {
  description = "Latencia media (p95) das APIs a partir da qual o alerta dispara."
  type        = number
  default     = 1.5
}

variable "error_rate_threshold_percent" {
  description = "Percentual de transacoes com erro a partir do qual o alerta dispara."
  type        = number
  default     = 5
}

variable "container_memory_threshold_percent" {
  description = "Uso de memoria do container em relacao ao limite a partir do qual alerta."
  type        = number
  default     = 85
}

variable "container_cpu_threshold_percent" {
  description = "Uso de CPU do container em relacao ao limite a partir do qual alerta."
  type        = number
  default     = 85
}
