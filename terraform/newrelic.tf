# ---------------------------------------------------------------------------
# Observabilidade do cluster: nri-bundle
#
# Mesmo conteudo do infra/kind, apontando para o cluster EKS. Com license key
# vazia o recurso nao e criado, permitindo subir o lab sem depender do New Relic.
# ---------------------------------------------------------------------------

resource "helm_release" "newrelic_bundle" {
  count = var.newrelic_license_key == "" ? 0 : 1

  name       = "newrelic-bundle"
  repository = "https://helm-charts.newrelic.com"
  chart      = "nri-bundle"
  version    = var.newrelic_bundle_version != "" ? var.newrelic_bundle_version : null

  namespace        = "newrelic"
  create_namespace = true

  timeout = 900
  atomic  = true

  set_sensitive {
    name  = "global.licenseKey"
    value = var.newrelic_license_key
  }

  set {
    name  = "global.cluster"
    value = local.cluster_name
  }

  set {
    name  = "global.lowDataMode"
    value = tostring(var.newrelic_low_data_mode)
  }

  # Metricas de infraestrutura do Kubernetes (CPU / memoria de node, pod e container).
  set {
    name  = "newrelic-infrastructure.enabled"
    value = "true"
  }

  set {
    name  = "newrelic-infrastructure.privileged"
    value = "true"
  }

  # Estado dos objetos do cluster, incluindo replicas do HPA.
  set {
    name  = "kube-state-metrics.enabled"
    value = "true"
  }

  # Eventos do cluster: reinicios, falhas de probe, OOMKilled.
  set {
    name  = "nri-kube-events.enabled"
    value = "true"
  }

  # Coleta o stdout dos pods, que no profile "prod" ja e JSON estruturado.
  set {
    name  = "newrelic-logging.enabled"
    value = "true"
  }

  # A instrumentacao da aplicacao vem do agente Java, nao de scrape Prometheus.
  set {
    name  = "newrelic-prometheus-agent.enabled"
    value = "false"
  }

  depends_on = [aws_eks_node_group.node_group]
}
