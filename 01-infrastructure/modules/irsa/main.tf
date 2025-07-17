resource "aws_iam_role" "ebs_csi_driver" {
  name = "${var.cluster_name}-ebs-csi-driver-irsa"

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
          "${var.oidc_provider_url}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ebs_csi_driver" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_driver.name
}

resource "aws_iam_role" "external_secrets_irsa" {
  name = "${var.cluster_name}-external_secrets-irsa"

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
          "${var.oidc_provider_url}:sub" = "system:serviceaccount:external-secrets:external-secrets"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "external_secrets_policy" {
  name = "${var.cluster_name}-external_secrets-policy"
  role = aws_iam_role.external_secrets_irsa.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "ssm:GetParameter",
        "ssm:GetParameters",
        "ssm:GetParametersByPath"
      ],
      Resource = var.ssm_parameter_arns
    }]
  })
}

resource "aws_iam_role" "alb_controller" {
  name = "${var.cluster_name}-alb-controller-irsa"

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
          "${var.oidc_provider_url}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
        }
      }
    }]
  })
}

locals {
  alb_controller_policy = jsondecode(file("${path.module}/iam_policies/alb_iam_policy.json"))
}

resource "aws_iam_policy" "alb_controller" {
  name   = "AWSLoadBalancerControllerIAMPolicy"
  policy = jsonencode(local.alb_controller_policy)
}

resource "aws_iam_role_policy_attachment" "alb_controller" {
  policy_arn = aws_iam_policy.alb_controller.arn
  role       = aws_iam_role.alb_controller.name
}


resource "aws_iam_role" "external_dns_irsa" {
  name = "${var.cluster_name}-external-dns-irsa"

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
          "${var.oidc_provider_url}:sub" = "system:serviceaccount:external-dns:external-dns"
        }
      }
    }]
  })
}

resource "aws_iam_policy" "external_dns" {
  name   = "${var.cluster_name}-external-dns-policy"
  policy = file("${path.module}/iam_policies/external_dns_iam_policy.json")
}

resource "aws_iam_role_policy_attachment" "external_dns" {
  role       = aws_iam_role.external_dns_irsa.name
  policy_arn = aws_iam_policy.external_dns.arn
}


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