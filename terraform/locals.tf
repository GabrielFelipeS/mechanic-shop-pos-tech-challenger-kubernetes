locals {
  # O AWS Academy nao permite iam:CreateRole / iam:AttachRolePolicy / iam:CreateOpenIDConnectProvider.
  # A conta ja vem com a LabRole pronta, com permissoes de EKS, EC2 e EBS, e com trust policy
  # que aceita eks.amazonaws.com e ec2.amazonaws.com. Por isso a mesma role e usada pelo
  # control plane e pelos nodes, e o ARN e montado a partir do account id (sem chamar a API de IAM,
  # que tambem pode estar bloqueada para leitura em alguns labs).
  lab_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.lab_role_name}"

  cluster_name = "eks-${var.project_name}"

  node_public_ip = length(data.aws_instances.nodes.public_ips) > 0 ? data.aws_instances.nodes.public_ips[0] : ""

  mailpit_ui_url = local.node_public_ip == "" ? "" : "http://${local.node_public_ip}:${var.mailpit_ui_node_port}"

}
