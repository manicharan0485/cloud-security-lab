# EKS control plane + a managed node group, wired to the private subnets
# defined in network.tf. This is deliberately minimal - the point is to show
# the security-relevant knobs, not build a production-grade module.

resource "aws_eks_cluster" "main" {
  name     = var.project_name
  role_arn = aws_iam_role.eks_cluster.arn
  version  = "1.29"

  vpc_config {
    subnet_ids              = concat(aws_subnet.private[*].id, aws_subnet.public[*].id)
    endpoint_private_access  = true
    endpoint_public_access   = true
    # In a real prod build, restrict this instead of leaving it open:
    public_access_cidrs      = ["YOUR_OFFICE_OR_VPN_CIDR/32"]
  }

  # Turn on control-plane audit logging - this is what you'd point to if
  # asked "how would you investigate who did what against the API server".
  enabled_cluster_log_types = ["api", "audit", "authenticator"]

  encryption_config {
    resources = ["secrets"]
    provider {
      key_arn = aws_kms_key.eks_secrets.arn
    }
  }
}

# Encrypt Kubernetes Secrets at rest in etcd using a customer-managed KMS key
resource "aws_kms_key" "eks_secrets" {
  description             = "EKS secrets encryption for ${var.project_name}"
  deletion_window_in_days = 30
  enable_key_rotation      = true
}

resource "aws_eks_node_group" "default" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.project_name}-default"
  node_role_arn   = aws_iam_role.eks_nodes.arn

  # Worker nodes live in private subnets only - no public IP, no direct
  # inbound route from the internet.
  subnet_ids = aws_subnet.private[*].id

  scaling_config {
    desired_size = 2
    max_size     = 4
    min_size     = 1
  }

  instance_types = ["t3.medium"]
}
