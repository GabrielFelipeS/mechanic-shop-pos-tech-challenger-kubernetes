output "dashboard_permalink" {
  description = "Link direto para o dashboard criado."
  value       = newrelic_one_dashboard.mechanic_shop.permalink
}

output "alert_policy_id" {
  description = "ID da politica de alertas."
  value       = newrelic_alert_policy.mechanic_shop.id
}

output "synthetics_monitor_id" {
  description = "GUID do monitor de uptime."
  value       = newrelic_synthetics_monitor.health.id
}
