locals {
  cluster_name = "eks-${var.project_name}"

  node_public_ip = length(data.aws_instances.nodes.public_ips) > 0 ? data.aws_instances.nodes.public_ips[0] : ""

  mailpit_ui_url = local.node_public_ip == "" ? "" : "http://${local.node_public_ip}:${var.mailpit_ui_node_port}"

}
