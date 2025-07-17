variable "cluster_name" {}
variable "db_subnet_ids" {
  type = list(string)
}
variable "private_subnet_cidrs" {
  type = list(string)
}
variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "rds_config" {
  description = "RDS configuration"
  type = object({
    db_name           = string
    db_username       = string
    engine            = string
    engine_version    = string
    port              = number
    instance_class    = string
    allocated_storage = number
  })
}

variable "enabled" {
  description = "Whether to enable the RDS module"
  type        = bool
  default     = false
}