variable "cluster_name" {}
variable "karpenter-controller-role" {}
variable "cluster_endpoint" {}
variable "interruption_queue_url" {}
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