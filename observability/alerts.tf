# ---------------------------------------------------------------------------
# Politica de alertas
#
# Cobre os quatro itens exigidos pelo Tech Challenge:
#   - latencia das APIs
#   - consumo de recursos do Kubernetes (CPU / memoria)
#   - healthchecks e uptime
#   - falhas no processamento de ordens de servico
# ---------------------------------------------------------------------------

resource "newrelic_alert_policy" "mechanic_shop" {
  name                = "mechanic-shop / production"
  incident_preference = "PER_CONDITION_AND_TARGET"
}

# --- Falhas no processamento de ordens de servico ---------------------------
# Alimentado pelo evento customizado MechanicShopServiceOrderFailure, emitido
# por ObservabilityReporter quando o processamento assincrono de uma OS falha.
resource "newrelic_nrql_alert_condition" "service_order_failures" {
  policy_id = newrelic_alert_policy.mechanic_shop.id
  name      = "Falhas no processamento de ordens de servico"
  type      = "static"
  enabled   = true

  aggregation_method = "event_flow"
  aggregation_window = 60
  aggregation_delay  = 120

  violation_time_limit_seconds = 3600

  nrql {
    query = "SELECT count(*) FROM MechanicShopServiceOrderFailure"
  }

  critical {
    operator              = "above_or_equals"
    threshold             = 1
    threshold_duration    = 120
    threshold_occurrences = "at_least_once"
  }
}

# --- Falhas de integracao (SMTP e demais dependencias externas) -------------
resource "newrelic_nrql_alert_condition" "integration_failures" {
  policy_id = newrelic_alert_policy.mechanic_shop.id
  name      = "Falhas nas integracoes externas"
  type      = "static"
  enabled   = true

  aggregation_method = "event_flow"
  aggregation_window = 60
  aggregation_delay  = 120

  violation_time_limit_seconds = 3600

  nrql {
    query = "SELECT count(*) FROM MechanicShopIntegrationFailure FACET integration"
  }

  critical {
    operator              = "above"
    threshold             = 3
    threshold_duration    = 300
    threshold_occurrences = "all"
  }
}

# --- Latencia das APIs ------------------------------------------------------
resource "newrelic_nrql_alert_condition" "api_latency" {
  policy_id = newrelic_alert_policy.mechanic_shop.id
  name      = "Latencia das APIs (p95) acima do limite"
  type      = "static"
  enabled   = true

  aggregation_method = "event_flow"
  aggregation_window = 60
  aggregation_delay  = 120

  violation_time_limit_seconds = 3600

  nrql {
    query = "SELECT percentile(duration, 95) FROM Transaction WHERE appName = '${var.app_name}' AND transactionType = 'Web'"
  }

  critical {
    operator              = "above"
    threshold             = var.api_latency_threshold_seconds
    threshold_duration    = 300
    threshold_occurrences = "all"
  }
}

# --- Taxa de erro HTTP ------------------------------------------------------
resource "newrelic_nrql_alert_condition" "api_error_rate" {
  policy_id = newrelic_alert_policy.mechanic_shop.id
  name      = "Taxa de erro das APIs acima do limite"
  type      = "static"
  enabled   = true

  aggregation_method = "event_flow"
  aggregation_window = 60
  aggregation_delay  = 120

  violation_time_limit_seconds = 3600

  nrql {
    query = "SELECT percentage(count(*), WHERE error IS true) FROM Transaction WHERE appName = '${var.app_name}'"
  }

  critical {
    operator              = "above"
    threshold             = var.error_rate_threshold_percent
    threshold_duration    = 300
    threshold_occurrences = "all"
  }
}

# --- Consumo de memoria dos containers no Kubernetes ------------------------
resource "newrelic_nrql_alert_condition" "k8s_container_memory" {
  policy_id = newrelic_alert_policy.mechanic_shop.id
  name      = "Memoria do container acima do limite"
  type      = "static"
  enabled   = true

  aggregation_method = "event_flow"
  aggregation_window = 60
  aggregation_delay  = 180

  violation_time_limit_seconds = 3600

  nrql {
    query = "SELECT average(memoryWorkingSetUtilization) FROM K8sContainerSample WHERE clusterName = '${var.cluster_name}' AND containerName = '${var.workload_name}' FACET podName"
  }

  critical {
    operator              = "above"
    threshold             = var.container_memory_threshold_percent
    threshold_duration    = 300
    threshold_occurrences = "all"
  }
}

# --- Consumo de CPU dos containers no Kubernetes ----------------------------
resource "newrelic_nrql_alert_condition" "k8s_container_cpu" {
  policy_id = newrelic_alert_policy.mechanic_shop.id
  name      = "CPU do container acima do limite"
  type      = "static"
  enabled   = true

  aggregation_method = "event_flow"
  aggregation_window = 60
  aggregation_delay  = 180

  violation_time_limit_seconds = 3600

  nrql {
    query = "SELECT average(cpuCoresUtilization) FROM K8sContainerSample WHERE clusterName = '${var.cluster_name}' AND containerName = '${var.workload_name}' FACET podName"
  }

  critical {
    operator              = "above"
    threshold             = var.container_cpu_threshold_percent
    threshold_duration    = 300
    threshold_occurrences = "all"
  }
}

# --- Pods reiniciando / fora do ar ------------------------------------------
resource "newrelic_nrql_alert_condition" "k8s_pod_not_ready" {
  policy_id = newrelic_alert_policy.mechanic_shop.id
  name      = "Pods da aplicacao fora de Running"
  type      = "static"
  enabled   = true

  aggregation_method = "event_flow"
  aggregation_window = 60
  aggregation_delay  = 180

  violation_time_limit_seconds = 3600

  nrql {
    query = "SELECT uniqueCount(podName) FROM K8sPodSample WHERE clusterName = '${var.cluster_name}' AND podName LIKE '${var.workload_name}%' AND status != 'Running'"
  }

  critical {
    operator              = "above"
    threshold             = 0
    threshold_duration    = 300
    threshold_occurrences = "all"
  }
}

# --- Uptime do healthcheck (Synthetics) -------------------------------------
resource "newrelic_nrql_alert_condition" "healthcheck_down" {
  policy_id = newrelic_alert_policy.mechanic_shop.id
  name      = "Healthcheck indisponivel"
  type      = "static"
  enabled   = true

  aggregation_method = "event_flow"
  aggregation_window = 60
  aggregation_delay  = 120

  violation_time_limit_seconds = 3600

  nrql {
    query = "SELECT count(*) FROM SyntheticCheck WHERE monitorName = '${newrelic_synthetics_monitor.health.name}' AND result = 'FAILED'"
  }

  critical {
    operator              = "above_or_equals"
    threshold             = 1
    threshold_duration    = 180
    threshold_occurrences = "at_least_once"
  }
}
