output "ebs_csi_role_arn" {
  value       = aws_iam_role.ebs_csi_driver.arn
  description = "IAM role ARN for the EBS CSI Driver"
}

output "external-secrets_role_arn" {
  value       = aws_iam_role.external_secrets_irsa.arn
  description = "IAM role ARN for the external secrets"
}

output "alb-controller_role_arn" {
  value       = aws_iam_role.alb_controller.arn
  description = "IAM role ARN for ALB controller"
}

output "external_dns_role_arn" {
  value       = aws_iam_role.external_dns_irsa.arn
  description = "IAM role ARN for external dns controller"
}

output "karpenter-controller-role" {
  value       = aws_iam_role.karpenter-controller-role.arn
  description = "IAM role ARN for karpenter"
}