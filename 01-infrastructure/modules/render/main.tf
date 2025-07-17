locals {
  helm_charts_input_path = "/templates/helm-charts-values"
  values = {
    "aws-ebs-csi-driver-values.yaml" = templatefile("${path.module}${local.helm_charts_input_path}/aws-ebs-csi-driver-values.yaml.tmpl", {
      ebs_csi_irsa_arn = var.ebs_irsa_arn
    })

    "external-secrets-values.yaml" = templatefile("${path.module}${local.helm_charts_input_path}/external-secrets-values.yaml.tmpl", {
      external_secrets_irsa_arn = var.external_secrets_irsa_arn
    })

    "aws-load-balancer-controller-values.yaml" = templatefile("${path.module}${local.helm_charts_input_path}/aws-load-balancer-controller-values.yaml.tmpl", {
      alb_controller_irsa_arn = var.alb_controller_irsa_arn
      cluster_name            = var.cluster_name
      vpc_id                  = var.vpc_id
    })

    "external-dns-values.yaml" = templatefile("${path.module}${local.helm_charts_input_path}/external-dns-values.yaml.tmpl", {
      external_dns_irsa_arn = var.external_dns_irsa_arn
      domain_name           = var.domain_name
    })

    "karpenter-values.yaml" = templatefile("${path.module}${local.helm_charts_input_path}/karpenter-values.yaml.tmpl", {
      karpenter-controller-role = var.karpenter-controller-role
      cluster_name              = var.cluster_name
      cluster_endpoint          = var.cluster_endpoint
      interruption_queue_url    = var.interruption_queue_url
    })
  }
}

locals {
  manifests_input_path = "/templates/manifests/"
  manifests = {
    "ec2-node-class.yaml" = templatefile("${path.module}${local.manifests_input_path}/ec2-node-class.yaml.tftpl", {

      cluster_name            = var.cluster_name
      karpenter_node_role_arn = var.karpenter_node_role_arn
      # instance_profile          = var.instance_profile_name
      karpenter_nodepool_config = var.karpenter_nodepool_config
    })

    "node-pool.yaml" = templatefile("${path.module}${local.manifests_input_path}/node-pool.yaml.tftpl", {

      cluster_name = var.cluster_name
      # instance_profile          = var.instance_profile_name
      karpenter_nodepool_config = var.karpenter_nodepool_config
    })

    "aws-auth-karpenter.yaml" = templatefile("${path.module}${local.manifests_input_path}/aws-auth-karpenter.yaml.tfpl", {

      cluster_name            = var.cluster_name
      karpenter_node_role_arn = var.karpenter_node_role_arn
      eks_node_role_arn       = var.eks_node_role_arn
    })
  }
}

resource "local_file" "rendered_values" {
  for_each = local.values

  content  = each.value
  filename = "${path.module}/../../../02-helm-charts/values/${each.key}"
}

resource "local_file" "rendered_manifests" {
  for_each = local.manifests

  content  = each.value
  filename = "${path.module}/../../../03-manifests/${each.key}"
}