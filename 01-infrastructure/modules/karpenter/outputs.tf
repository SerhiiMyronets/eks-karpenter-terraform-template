output "interruption_queue_url" {
  value = aws_sqs_queue.karpenter_interruption.url
}
output "interruption_queue_arn" {
  value = aws_sqs_queue.karpenter_interruption.arn
}

# output "instance_profile_name" {
#   value = aws_iam_instance_profile.karpenter.name
# }

output "karpenter_node_role_arn" {
  value = aws_iam_role.karpenter-node-role.arn
}