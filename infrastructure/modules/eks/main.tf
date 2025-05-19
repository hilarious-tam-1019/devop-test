# EKS Cluster Module
module "eks_iam" {
  source    = "../../modules/eks_iam"
  role_name = "${var.name}-${var.environment}-eks-role"
}

module "vpc" {
  source               = "../../modules/vpc"
  name                 = "${var.name}-vpc"
  availability_zones   = var.availability_zones
  private_subnet_cidrs = var.private_subnet_cidrs
  cidr_block           = var.cidr_block
  public_subnet_cidrs  = var.public_subnet_cidrs
  enable_nat_gateway   = var.enable_nat_gateway
}

resource "aws_eks_cluster" "eks" {
  name     = var.name
  role_arn = module.eks_iam.eks_role_arn

  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  vpc_config {
    subnet_ids = module.vpc.private_subnet_ids
  }
}

resource "aws_eks_node_group" "eks_node_group" {
  cluster_name    = var.name
  node_group_name = var.node_group_name
  node_role_arn   = module.eks_iam.eks_node_group_role_arn
  subnet_ids      = module.vpc.private_subnet_ids
  instance_types  = var.instance_types

  depends_on = [
    aws_eks_cluster.eks
  ]


  scaling_config {
    desired_size = var.node_group_size
    max_size     = var.node_group_max_size
    min_size     = var.node_group_min_size
  }

  capacity_type = var.capacity_type
  disk_size     = 50

  tags = var.tags
}

