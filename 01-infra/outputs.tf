output "cluster_name" {
  value = var.cluster_name
}

output "karpenter_controller_role_arn" {
  value = module.iam.karpenter-controller-role-arn
}

output "karpenter_node_role_arn" {
  value = module.iam.karpenter_node_role_arn
}

output "interruption_queue_name" {
  value = module.sqs.interruption_queue_name
}

output "eks_node_role_arn" {
  value = module.eks.eks_node_role_arn
}

output "z_aws_connection_command" {
  value = join("\n", [
    "",
    "  Connect to your EKS cluster:",
    "  aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}",
    "",
    "  Export outputs to JSON (for gomplate):",
    "  terraform output -json > ../02-render/outputs.json",
    ""
  ])
}