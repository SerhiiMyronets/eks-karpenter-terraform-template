# data "aws_eks_cluster" "main" {
#   name       = module.eks.cluster_name
#   depends_on = [module.eks]
# }
#
# data "aws_eks_cluster_auth" "main" {
#   name       = module.eks.cluster_name
#   depends_on = [module.eks]
# }

module "vpc" {
  source = "./modules/vpc"

  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  private_subnet_cidrs = var.private_subnet_cidrs
  public_subnet_cidrs  = var.public_subnet_cidrs
  cluster_name         = var.cluster_name
}

module "eks" {
  source = "./modules/eks"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  subnet_ids      = module.vpc.private_subnet_ids
  node_groups     = var.node_groups_config
}

module "rds" {
  source = "./modules/rds"

  enabled = var.enable_rds

  cluster_name         = var.cluster_name
  rds_config           = var.rds_config
  db_subnet_ids        = module.vpc.private_subnet_ids
  private_subnet_cidrs = var.private_subnet_cidrs
  vpc_id               = module.vpc.vpc_id
}



module "karpenter" {
  source       = "./modules/karpenter"
  vpc_id       = module.vpc.vpc_id
  cluster_name = var.cluster_name
}

module "irsa" {
  source                 = "./modules/irsa"
  cluster_name           = var.cluster_name
  aws_region             = var.region
  oidc_provider_arn      = module.eks.oidc_provider_arn
  oidc_provider_url      = module.eks.oidc_provider_url
  interruption_queue_arn = module.karpenter.interruption_queue_arn
  ssm_parameter_arns     = var.enable_rds ? module.rds.db_credential_arns : ["arn:aws:ssm:::"]
}

module "render" {
  source = "./modules/render"

  ebs_irsa_arn              = module.irsa.ebs_csi_role_arn
  external_secrets_irsa_arn = module.irsa.external-secrets_role_arn
  alb_controller_irsa_arn   = module.irsa.alb-controller_role_arn
  external_dns_irsa_arn     = module.irsa.external_dns_role_arn
  karpenter-controller-role = module.irsa.karpenter-controller-role
  # instance_profile_name     = module.karpenter.instance_profile_name
  interruption_queue_url    = module.karpenter.interruption_queue_url
  karpenter_nodepool_config = var.karpenter_nodepool_config
  karpenter_node_role_arn   = module.karpenter.karpenter_node_role_arn
  eks_node_role_arn         = module.eks.eks_node_role_arn
  cluster_endpoint          = module.eks.cluster_endpoint
  cluster_name              = var.cluster_name
  vpc_id                    = module.vpc.vpc_id
  domain_name               = var.domain_name
}

module "acm" {
  source      = "./modules/acm"
  domain_name = var.domain_name
}