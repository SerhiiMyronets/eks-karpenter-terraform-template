

output "karpenter-controller-role-arn" {
  value       = aws_iam_role.karpenter-controller-role.arn
  description = "IAM role ARN for karpenter"
}
output "karpenter_node_role_arn" {
  value = aws_iam_role.karpenter-node-role.arn
}