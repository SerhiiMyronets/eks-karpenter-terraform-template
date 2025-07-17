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

resource "aws_iam_role_policy" "this" {
  name   = "${var.cluster_name}-karpenter-controller-policy"
  role   = aws_iam_role.karpenter-controller-role.id
  policy = local.karpenter_policy
}

locals {
  karpenter_policy = templatefile("${path.module}/iam_policies/tamplates/karpenter_controller-policy.json.tmpl", {
    AWS_ACCOUNT_ID         = data.aws_caller_identity.current.account_id
    AWS_PARTITION          = data.aws_partition.current.partition
    CLUSTER_NAME           = var.cluster_name
    AWS_REGION             = var.aws_region
    INTERRUPTION_QUEUE_ARN = var.interruption_queue_arn
  })
}


resource "local_file" "karpenter_policy" {
  content  = local.karpenter_policy
  filename = "${path.module}/iam_policies/karpenter_controller-policy.json"
}

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}