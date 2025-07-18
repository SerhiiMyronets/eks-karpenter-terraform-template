locals {
  helm_charts_input_path = "/templates/helm-charts-values"
  values = {

    "karpenter-values.yaml" = templatefile("${path.module}/templates/helm-charts-values/karpenter-values.yaml.tfpl", {
      karpenter-controller-role = var.karpenter-controller-role
      cluster_name              = var.cluster_name
      interruption_queue_name   = var.interruption_queue_name
    })
  }
}

locals {
  manifests_input_path = "/templates/manifests/"
  manifests = {

    "ec2-node-class.yaml" = templatefile("${path.module}/templates/manifests/ec2-node-class.yaml.tftpl", {
      cluster_name            = var.cluster_name
      karpenter_node_role_arn = var.karpenter_node_role_arn
    })

    "aws-auth-karpenter.yaml" = templatefile("${path.module}/templates/manifests/aws-auth-karpenter.yaml.tfpl", {
      cluster_name            = var.cluster_name
      karpenter_node_role_arn = var.karpenter_node_role_arn
      eks_node_role_arn       = var.eks_node_role_arn

    })
  }
}

resource "local_file" "rendered_values" {
  for_each = local.values

  content  = each.value
  filename = "${path.module}/../../../02-helm-chart/values/${each.key}"
}

resource "local_file" "rendered_manifests" {
  for_each = local.manifests

  content  = each.value
  filename = "${path.module}/../../../03-manifests/${each.key}"
}