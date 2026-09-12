# ---------------------------------------------------------------------------
# Launch template dos nodes
#
# Existe por um unico motivo: o limite de hops do IMDS.
#
# O launch template que o EKS gera sozinho para um managed node group usa
# http_put_response_hop_limit = 1, o que impede qualquer pod SEM hostNetwork de
# alcancar o IMDS e, portanto, de obter as credenciais da role do node.
#
# Como neste cluster nao ha IRSA (o AWS Academy bloqueia a criacao do OIDC
# provider), o IMDS e a UNICA fonte de credenciais AWS para os pods. Com hop
# limit 1 o resultado e:
#
#   ebs-csi-node       (DaemonSet, hostNetwork: true)  -> funciona
#   ebs-csi-controller (Deployment, hostNetwork: false) -> ebs-plugin em
#                       CrashLoopBackOff, addon preso em CREATING para sempre
#
# Subir o hop limit para 2 resolve: o pacote sai do pod, passa pelo host e
# chega ao IMDS. Como o launch template nao define image_id nem user_data, o
# EKS continua injetando a AMI otimizada e o bootstrap do node normalmente.
# ---------------------------------------------------------------------------

resource "aws_launch_template" "node" {
  name_prefix = "lt-${var.project_name}-"
  description = "Nodes do EKS com IMDS hop limit 2 (necessario sem IRSA)"

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = var.imds_hop_limit
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = var.node_disk_size
      volume_type           = "gp3"
      delete_on_termination = true
      encrypted             = true
    }
  }

  # Nenhum vpc_security_group_ids aqui de proposito: quando o launch template
  # declara security groups, o EKS deixa de anexar o cluster security group aos
  # nodes, e a regra de NodePort em network.tf perderia o efeito.

  tag_specifications {
    resource_type = "instance"

    tags = merge(var.tags, {
      Name = "node-${var.project_name}"
    })
  }

  lifecycle {
    create_before_destroy = true
  }
}
