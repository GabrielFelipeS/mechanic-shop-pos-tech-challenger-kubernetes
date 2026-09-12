# ---------------------------------------------------------------------------
# Dashboard
#
# Pagina 1 - Ordens de servico : os tres graficos exigidos pelo desafio
#              (volume diario, tempo medio por status, erros de integracao)
# Pagina 2 - APIs              : latencia, throughput e taxa de erro
# Pagina 3 - Kubernetes        : CPU, memoria, replicas e uptime
# ---------------------------------------------------------------------------

resource "newrelic_one_dashboard" "mechanic_shop" {
  name        = "Mechanic Shop / production"
  description = "Observabilidade da oficina: ordens de servico, APIs e Kubernetes."
  permissions = "public_read_write"

  # =========================================================================
  page {
    name = "Ordens de servico"

    widget_line {
      title  = "Volume diario de ordens de servico"
      row    = 1
      column = 1
      width  = 6
      height = 3

      nrql_query {
        account_id = var.newrelic_account_id
        query      = "SELECT count(*) AS 'Ordens abertas' FROM MechanicShopServiceOrderOpened SINCE 30 days ago TIMESERIES 1 day"
      }
    }

    widget_billboard {
      title  = "Ordens abertas hoje"
      row    = 1
      column = 7
      width  = 3
      height = 3

      nrql_query {
        account_id = var.newrelic_account_id
        query      = "SELECT count(*) AS 'Hoje' FROM MechanicShopServiceOrderOpened SINCE today"
      }
    }

    widget_billboard {
      title  = "Falhas no processamento de OS (24h)"
      row    = 1
      column = 10
      width  = 3
      height = 3

      nrql_query {
        account_id = var.newrelic_account_id
        query      = "SELECT count(*) AS 'Falhas' FROM MechanicShopServiceOrderFailure SINCE 24 hours ago"
      }

      warning  = 1
      critical = 5
    }

    # Tempo medio de execucao por status. As duracoes vem do atributo
    # phaseDurationSeconds emitido por ServiceOrderObservabilityListener:
    #   DIAGNOSIS    = abertura da OS -> aprovacao do orcamento
    #   EXECUTION    = aprovacao do orcamento -> conclusao do servico
    #   FINALIZATION = conclusao do servico -> entrega do veiculo
    widget_bar {
      title  = "Tempo medio por status (minutos)"
      row    = 4
      column = 1
      width  = 6
      height = 3

      nrql_query {
        account_id = var.newrelic_account_id
        query      = "SELECT average(phaseDurationSeconds) / 60 AS 'Minutos' FROM MechanicShopServiceOrderStatusChanged WHERE phase IS NOT NULL SINCE 7 days ago FACET phase"
      }
    }

    widget_line {
      title  = "Tempo medio por status ao longo do tempo (minutos)"
      row    = 4
      column = 7
      width  = 6
      height = 3

      nrql_query {
        account_id = var.newrelic_account_id
        query      = "SELECT average(phaseDurationSeconds) / 60 AS 'Minutos' FROM MechanicShopServiceOrderStatusChanged WHERE phase IS NOT NULL SINCE 7 days ago FACET phase TIMESERIES 1 hour"
      }
    }

    widget_table {
      title  = "Erros e falhas nas integracoes"
      row    = 7
      column = 1
      width  = 6
      height = 3

      nrql_query {
        account_id = var.newrelic_account_id
        query      = "SELECT count(*) AS 'Ocorrencias', latest(errorMessage) AS 'Ultima mensagem' FROM MechanicShopIntegrationFailure SINCE 24 hours ago FACET integration, operation, errorClass"
      }
    }

    widget_table {
      title  = "Transicoes de status recentes"
      row    = 7
      column = 7
      width  = 6
      height = 3

      nrql_query {
        account_id = var.newrelic_account_id
        query      = "SELECT serviceOrderId, oldStatus, newStatus, phaseDurationSeconds, correlationId FROM MechanicShopServiceOrderStatusChanged SINCE 6 hours ago LIMIT 50"
      }
    }
  }

  # =========================================================================
  page {
    name = "APIs"

    widget_line {
      title  = "Latencia das APIs (media / p95 / p99)"
      row    = 1
      column = 1
      width  = 8
      height = 3

      nrql_query {
        account_id = var.newrelic_account_id
        query      = "SELECT average(duration) AS 'Media', percentile(duration, 95) AS 'p95', percentile(duration, 99) AS 'p99' FROM Transaction WHERE appName = '${var.app_name}' AND transactionType = 'Web' SINCE 6 hours ago TIMESERIES"
      }
    }

    widget_billboard {
      title  = "Taxa de erro (%)"
      row    = 1
      column = 9
      width  = 4
      height = 3

      nrql_query {
        account_id = var.newrelic_account_id
        query      = "SELECT percentage(count(*), WHERE error IS true) AS 'Erros' FROM Transaction WHERE appName = '${var.app_name}' SINCE 1 hour ago"
      }

      warning  = 1
      critical = var.error_rate_threshold_percent
    }

    widget_table {
      title  = "Endpoints mais lentos"
      row    = 4
      column = 1
      width  = 6
      height = 3

      nrql_query {
        account_id = var.newrelic_account_id
        query      = "SELECT count(*) AS 'Chamadas', average(duration) AS 'Media (s)', percentile(duration, 95) AS 'p95 (s)' FROM Transaction WHERE appName = '${var.app_name}' AND transactionType = 'Web' SINCE 6 hours ago FACET name LIMIT 20"
      }
    }

    widget_table {
      title  = "Erros por tipo"
      row    = 4
      column = 7
      width  = 6
      height = 3

      nrql_query {
        account_id = var.newrelic_account_id
        query      = "SELECT count(*) AS 'Ocorrencias' FROM TransactionError WHERE appName = '${var.app_name}' SINCE 24 hours ago FACET error.class, transactionName LIMIT 20"
      }
    }

    widget_table {
      title  = "Logs estruturados com correlacao (ultimos erros)"
      row    = 7
      column = 1
      width  = 12
      height = 3

      nrql_query {
        account_id = var.newrelic_account_id
        query      = "SELECT timestamp, level, correlationId, trace.id, message FROM Log WHERE level IN ('ERROR', 'WARN') SINCE 6 hours ago LIMIT 100"
      }
    }
  }

  # =========================================================================
  page {
    name = "Kubernetes"

    widget_line {
      title  = "CPU dos containers (cores)"
      row    = 1
      column = 1
      width  = 6
      height = 3

      nrql_query {
        account_id = var.newrelic_account_id
        query      = "SELECT average(cpuUsedCores) AS 'Cores' FROM K8sContainerSample WHERE clusterName = '${var.cluster_name}' SINCE 6 hours ago FACET containerName TIMESERIES"
      }
    }

    widget_line {
      title  = "Memoria dos containers (bytes)"
      row    = 1
      column = 7
      width  = 6
      height = 3

      nrql_query {
        account_id = var.newrelic_account_id
        query      = "SELECT average(memoryWorkingSetBytes) AS 'Working set' FROM K8sContainerSample WHERE clusterName = '${var.cluster_name}' SINCE 6 hours ago FACET containerName TIMESERIES"
      }
    }

    widget_line {
      title  = "Replicas da aplicacao (HPA)"
      row    = 4
      column = 1
      width  = 6
      height = 3

      nrql_query {
        account_id = var.newrelic_account_id
        query      = "SELECT latest(podsAvailable) AS 'Disponiveis', latest(podsDesired) AS 'Desejadas' FROM K8sDeploymentSample WHERE clusterName = '${var.cluster_name}' AND deploymentName = '${var.workload_name}' SINCE 6 hours ago TIMESERIES"
      }
    }

    widget_table {
      title  = "Restarts de container"
      row    = 4
      column = 7
      width  = 6
      height = 3

      nrql_query {
        account_id = var.newrelic_account_id
        query      = "SELECT latest(restartCount) AS 'Restarts' FROM K8sContainerSample WHERE clusterName = '${var.cluster_name}' SINCE 24 hours ago FACET podName, containerName LIMIT 20"
      }
    }

    widget_billboard {
      title  = "Uptime do healthcheck (%) - 24h"
      row    = 7
      column = 1
      width  = 4
      height = 3

      nrql_query {
        account_id = var.newrelic_account_id
        query      = "SELECT percentage(count(*), WHERE result = 'SUCCESS') AS 'Uptime' FROM SyntheticCheck WHERE monitorName = '${newrelic_synthetics_monitor.health.name}' SINCE 24 hours ago"
      }

      warning  = 99.5
      critical = 99
    }

    widget_line {
      title  = "Tempo de resposta do healthcheck (ms)"
      row    = 7
      column = 5
      width  = 8
      height = 3

      nrql_query {
        account_id = var.newrelic_account_id
        query      = "SELECT average(duration) AS 'ms' FROM SyntheticCheck WHERE monitorName = '${newrelic_synthetics_monitor.health.name}' SINCE 24 hours ago TIMESERIES"
      }
    }
  }
}
