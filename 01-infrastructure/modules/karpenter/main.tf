resource "aws_sqs_queue" "karpenter_interruption" {
  name = "${var.cluster_name}-karpenter-interruption"
}

resource "aws_sqs_queue_policy" "karpenter_interruption_policy" {
  queue_url = aws_sqs_queue.karpenter_interruption.id

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

resource "aws_iam_role" "karpenter-node-role" {
  name = "${var.cluster_name}-karpenter-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "karpenter_node" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ])

  role       = aws_iam_role.karpenter-node-role.name
  policy_arn = each.value
}

resource "aws_iam_service_linked_role" "spot" {
  aws_service_name = "spot.amazonaws.com"

  description = "Service-linked role for EC2 Spot Instances"
}

# resource "aws_iam_instance_profile" "karpenter" {
#   name = "${var.cluster_name}-karpenter-profile"
#   role = aws_iam_role.karpenter-node-role.name
# }
#
# resource "aws_security_group" "karpenter" {
#   name_prefix = "${var.cluster_name}-karpenter-"
#   description = "Security group for Karpenter nodes"
#   vpc_id      = var.vpc_id
#
#   tags = {
#     "karpenter-discovery/${var.cluster_name}" = "*"
#     "Name"                                    = "${var.cluster_name}-karpenter-sg"
#   }
#
#   ingress {
#     from_port = 0
#     to_port   = 0
#     protocol  = "-1"
#     self      = true
#   }
#
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }