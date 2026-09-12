output "cluster_name" {
  description = "Nome do cluster EKS."
  value       = aws_eks_cluster.cluster.name
}

output "cluster_endpoint" {
  description = "Endpoint do API server do EKS."
  value       = aws_eks_cluster.cluster.endpoint
}

output "kubeconfig_command" {
  description = "Comando para configurar o kubectl."
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${aws_eks_cluster.cluster.name}"
}

output "node_public_ips" {
  description = "IPs publicos dos nodes. Qualquer um deles atende os NodePorts."
  value       = data.aws_instances.nodes.public_ips
}

output "kong_admin_port_forward_command" {
  description = <<-EOT
    A Admin API do Kong e ClusterIP de proposito (expoe a config inteira,
    inclusive o segredo do JWT). Use port-forward para inspecionar.
  EOT
  value       = "kubectl -n ${var.namespace} port-forward svc/kong-admin 8001:8001"
}

output "mailpit_ui_url" {
  description = "URL publica da UI do Mailpit."
  value       = local.mailpit_ui_url
}

output "vpc_id" {
  description = "VPC compartilhada com o banco gerenciado."
  value       = aws_vpc.vpc.id
}

output "vpc_cidr" {
  description = "CIDR da VPC compartilhada com o banco gerenciado."
  value       = aws_vpc.vpc.cidr_block
}

output "private_subnet_ids" {
  description = "Subnets privadas a serem usadas pelo RDS."
  value       = aws_subnet.private[*].id
}

# ---------------------------------------------------------------------------
# Contrato com infra/newrelic/terraform
#
# Gerado automaticamente em observability.tf (local_file). Estes outputs
# existem para inspecao e para uso em pipelines.
# ---------------------------------------------------------------------------

output "newrelic_app_name" {
  description = "NEW_RELIC_APP_NAME reportado pela aplicacao (= var.app_name da stack)."
  value       = var.newrelic_app_name
}

output "newrelic_cluster_name" {
  description = "global.cluster reportado pelo nri-bundle (= var.cluster_name da stack)."
  value       = local.cluster_name
}

