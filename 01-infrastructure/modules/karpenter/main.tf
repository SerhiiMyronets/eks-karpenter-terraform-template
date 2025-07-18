# Kerpenter node role

resource "aws_iam_role" "karpenter-node-role" {
  name = "${var.cluster_name}-karpenter-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "karpenter_node" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ])

  role       = aws_iam_role.karpenter-node-role.name
  policy_arn = each.value
}

# Karpenter controller role

resource "aws_iam_role" "karpenter-controller-role" {
  name = "${var.cluster_name}-karpenter-controller-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Federated = var.oidc_provider_arn
      },
      Action = "sts:AssumeRoleWithWebIdentity",
      Condition = {
        StringEquals = {
          "${var.oidc_provider_url}:aud" = "sts.amazonaws.com",
          "${var.oidc_provider_url}:sub" = "system:serviceaccount:karpenter:karpenter"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "controller-policy" {
  name   = "${var.cluster_name}-karpenter-controller-policy"
  role   = aws_iam_role.karpenter-controller-role.id
  policy = templatefile("${path.module}/iam_policies/karpenter_controller-policy.json.tmpl", {
    AWS_ACCOUNT_ID         = data.aws_caller_identity.current.account_id
    AWS_PARTITION          = data.aws_partition.current.partition
    CLUSTER_NAME           = var.cluster_name
    AWS_REGION             = var.aws_region
    INTERRUPTION_QUEUE_ARN = var.interruption_queue_arn
  })
}

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

#

resource "aws_iam_service_linked_role" "spot" {
  aws_service_name = "spot.amazonaws.com"

  description = "Service-linked role for EC2 Spot Instances"
}