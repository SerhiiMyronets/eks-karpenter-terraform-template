variable "ebs_irsa_arn" {}
variable "external_secrets_irsa_arn" {}
variable "alb_controller_irsa_arn" {}
variable "cluster_name" {}
variable "vpc_id" {}
variable "external_dns_irsa_arn" {}
variable "domain_name" {}
variable "karpenter-controller-role" {}
variable "cluster_endpoint" {}
variable "interruption_queue_url" {}
# variable "instance_profile_name" {}
variable "karpenter_node_role_arn" {}
variable "eks_node_role_arn" {}

variable "karpenter_nodepool_config" {
  type = object({
    name           = string
    instance_types = list(string)
    capacity_type  = string
    cpu_limit      = number
    weight         = number
    ttl_minutes    = number
  })
}