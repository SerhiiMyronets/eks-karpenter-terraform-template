resource "aws_sqs_queue" "karpenter_interruption" {
  name = "${var.cluster_name}-karpenter-interruption"
}

resource "aws_sqs_queue_policy" "karpenter_interruption_policy" {
  queue_url = aws_sqs_queue.karpenter_interruption.url

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowEventBridge"
      Effect = "Allow"
      Principal = {
        Service = "events.amazonaws.com"
      }
      Action   = "sqs:SendMessage"
      Resource = aws_sqs_queue.karpenter_interruption.arn
    }]
  })
}

resource "aws_cloudwatch_event_rule" "karpenter_interruption" {
  name        = "${var.cluster_name}-karpenter-interruption"
  description = "Capture EC2 Spot Interruption Warnings"
  event_pattern = jsonencode({
    "source" : ["aws.ec2"],
    "detail-type" : ["EC2 Spot Instance Interruption Warning"]
  })
}

resource "aws_cloudwatch_event_target" "karpenter_interruption_target" {
  rule = aws_cloudwatch_event_rule.karpenter_interruption.name
  arn  = aws_sqs_queue.karpenter_interruption.arn
}