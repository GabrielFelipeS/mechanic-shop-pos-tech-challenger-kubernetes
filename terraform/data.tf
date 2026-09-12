data "aws_caller_identity" "current" {}

data "aws_eks_cluster_auth" "auth" {
  name = aws_eks_cluster.cluster.name
}

# IPs publicos dos nodes do managed node group. Como os services sao NodePort
# (mesmo modelo do Kind), sao esses IPs que dao acesso a API e ao Mailpit.
data "aws_instances" "nodes" {
  instance_tags = {
    "eks:cluster-name" = aws_eks_cluster.cluster.name
  }

  instance_state_names = ["running"]

  depends_on = [aws_eks_node_group.node_group]
}
