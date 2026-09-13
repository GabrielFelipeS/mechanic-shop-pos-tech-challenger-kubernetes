# ---------------------------------------------------------------------------
# Launch template dos nodes
#
# The launch template enforces IMDSv2 and configures the root EBS volume for
# managed nodes. No application workload stores persistent data on EBS; RDS
# owns PostgreSQL storage in the separate database repository.
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
