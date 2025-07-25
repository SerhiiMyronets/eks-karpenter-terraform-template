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

  cluster_name       = var.cluster_name
  cluster_version    = var.cluster_version
  node_groups_config = var.node_groups_config
  subnet_ids         = module.vpc.private_subnet_ids
  vpc_id             = module.vpc.vpc_id
}

module "sqs" {
  source       = "./modules/03-sqs"
  cluster_name = var.cluster_name
}

module "iam" {
  source                 = "./modules/04-iam"
  cluster_name           = var.cluster_name
  aws_region             = var.region
  oidc_provider_arn      = module.eks.oidc_provider_arn
  oidc_provider_url      = module.eks.oidc_provider_url
  interruption_queue_arn = module.sqs.interruption_queue_arn
}