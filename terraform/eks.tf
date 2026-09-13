# ---------------------------------------------------------------------------
# Cluster EKS
#
# The cluster and worker nodes use dedicated IAM roles declared in iam.tf.
# ---------------------------------------------------------------------------

resource "aws_eks_cluster" "cluster" {
  name     = local.cluster_name
  role_arn = aws_iam_role.eks_cluster.arn
  version  = var.cluster_version

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  vpc_config {
    subnet_ids              = aws_subnet.public[*].id
    endpoint_public_access  = true
    endpoint_private_access = true
    public_access_cidrs     = [var.api_server_allowed_cidr]
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy]
}

resource "aws_eks_node_group" "node_group" {
  cluster_name    = aws_eks_cluster.cluster.name
  node_group_name = "nodeg-${var.project_name}"
  node_role_arn   = aws_iam_role.eks_node.arn
  subnet_ids      = aws_subnet.public[*].id

  instance_types = [var.instance_type]
  capacity_type  = var.capacity_type

  # O disco vem do block_device_mappings do launch template: disk_size no node
  # group e mutuamente exclusivo com launch_template.
  launch_template {
    id      = aws_launch_template.node.id
    version = aws_launch_template.node.latest_version
  }

  scaling_config {
    desired_size = var.node_desired_size
    max_size     = var.node_max_size
    min_size     = var.node_min_size
  }

  update_config {
    max_unavailable = 1
  }

  lifecycle {
    # O desired_size passa a ser controlado pelo cluster-autoscaler/console depois do apply.
    ignore_changes = [scaling_config[0].desired_size]
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_node_worker,
    aws_iam_role_policy_attachment.eks_node_ecr_pull,
    aws_iam_role_policy_attachment.eks_node_cni,
    aws_iam_role_policy_attachment.eks_node_ebs_csi,
  ]
}

# The Java repository deploys Kubernetes manifests after building its image.
# Grant its dedicated GitHub Actions role Kubernetes-admin access without
# giving it permissions to create or alter AWS infrastructure.
resource "aws_eks_access_entry" "app_deployer" {
  cluster_name  = aws_eks_cluster.cluster.name
  principal_arn = var.app_deployer_role_arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "app_deployer_admin" {
  cluster_name  = aws_eks_cluster.cluster.name
  principal_arn = aws_eks_access_entry.app_deployer.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}

# ---------------------------------------------------------------------------
# Driver EBS CSI
#
# Necessary for persistent volumes. Without IRSA, the add-on uses the node
# role credentials, which include AmazonEBSCSIDriverPolicy.
#
# Essas credenciais so chegam ao ebs-csi-controller por causa do hop limit 2
# configurado em launch-template.tf. Sem aquele arquivo este addon trava.
# ---------------------------------------------------------------------------

resource "aws_eks_addon" "ebs_csi" {
  cluster_name                = aws_eks_cluster.cluster.name
  addon_name                  = "aws-ebs-csi-driver"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  # O addon so fica ACTIVE quando o ebs-csi-controller consegue falar com a API
  # da EC2, o que depende do hop limit do IMDS definido no launch template.
  depends_on = [aws_eks_node_group.node_group]

  timeouts {
    create = "30m"
    update = "30m"
  }
}
