variable "cluster_name" {
  type        = string
  description = "Name of the EKS cluster"
}

variable "oidc_provider_arn" {
  type        = string
  description = "ARN of the IAM OIDC provider"
}

variable "oidc_provider_url" {
  type        = string
  description = "URL of the OIDC provider (without https://)"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "interruption_queue_arn" {
  description = "interruption_queue_arn"
  type        = string
}