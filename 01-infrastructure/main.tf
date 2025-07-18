module "vpc" {
  source = "./modules/01-vpc"

  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  private_subnet_cidrs = var.private_subnet_cidrs
  public_subnet_cidrs  = var.public_subnet_cidrs
  cluster_name         = var.cluster_name
}

module "eks" {
  source = "./modules/02-eks"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  subnet_ids      = module.vpc.private_subnet_ids
  node_groups     = var.node_groups_config
}

module "sqs" {
  source                 = "./modules/03-sqs"
  cluster_name           = var.cluster_name
}

module "karpenter" {
  source       = "./modules/04-karpenter"
  oidc_provider_arn      = module.eks.oidc_provider_arn
  oidc_provider_url      = module.eks.oidc_provider_url
  interruption_queue_arn = module.sqs.interruption_queue_arn
  cluster_name = var.cluster_name
  aws_region = var.region
}

module "render" {
  source = "./modules/05-render"

  karpenter-controller-role = module.karpenter.karpenter-controller-role
  interruption_queue_url    = module.sqs.interruption_queue_url
  karpenter_nodepool_config = var.karpenter_nodepool_config
  karpenter_node_role_arn   = module.karpenter.karpenter_node_role_arn
  eks_node_role_arn         = module.eks.eks_node_role_arn
  cluster_endpoint          = module.eks.cluster_endpoint
  cluster_name              = var.cluster_name
}