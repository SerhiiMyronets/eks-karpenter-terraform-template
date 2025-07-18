output "interruption_queue_url" {
  value = aws_sqs_queue.karpenter_interruption.url
}
output "interruption_queue_arn" {
  value = aws_sqs_queue.karpenter_interruption.arn
}