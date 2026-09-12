# ---------------------------------------------------------------------------
# Healthchecks e uptime
#
# Monitor externo que chama /actuator/health a cada minuto de duas regioes.
# E o que produz a metrica de uptime exigida pelo desafio: as probes do
# Kubernetes so enxergam o pod de dentro do cluster.
# ---------------------------------------------------------------------------

resource "newrelic_synthetics_monitor" "health" {
  name   = "mechanic-shop healthcheck (production)"
  type   = "SIMPLE"
  status = "ENABLED"
  period = "EVERY_MINUTE"

  uri                       = var.health_check_url
  locations_public          = var.synthetics_locations
  verify_ssl                = true
  treat_redirect_as_failure = true

  tag {
    key    = "environment"
    values = ["production"]
  }

  tag {
    key    = "service"
    values = ["mechanic-shop"]
  }
}
