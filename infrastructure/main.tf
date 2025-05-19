
locals {
  env = terraform.workspace
}

provider "aws" {
  region = var.region
}

// Prod
# EKS 
module "eks" {
  count                     = terraform.workspace == "prod" ? 1 : 0
  source                    = "./modules/eks"
  name                      = "${var.name}-cluster"
  node_group_name           = "${var.name}-node-group"
  instance_types            = ["t3.large"]
  node_group_size           = 2
  node_group_max_size       = 3
  node_group_min_size       = 1
  environment               = var.environment
  capacity_type             = "SPOT"
  additional_instance_types = ["t3a.large", "t3a.xlarge"]
  tags                      = var.tags
  availability_zones        = var.availability_zones
  enable_nat_gateway        = var.enable_nat_gateway
}

# RDS
module "rds" {
  count               = terraform.workspace == "prod" ? 1 : 0
  source              = "./modules/rds"
  db_name             = "${var.name}-rds"
  environment         = var.environment
  subnet_ids          = module.eks[0].private_subnet_ids
  vpc_id              = module.eks[0].vpc_id
  allowed_cidr_blocks = var.allowed_cidr_blocks
  db_port             = var.db_port
  db_instance_class   = var.db_instance_class
}

# KMS
module "kms_backend" {
  count   = terraform.workspace == "prod" ? 1 : 0
  source  = "terraform-aws-modules/kms/aws"
  version = "~> 1.5"

  description = "KMS key for backend application secrets"

  enable_key_rotation     = true
  deletion_window_in_days = 7

  tags = {
    Project     = "coffeeshop"
    Environment = terraform.workspace
  }
}

# CI/CD
module "ci_cd" {
  count      = terraform.workspace == "prod" ? 1 : 0
  source     = "./modules/ci_cd"
  account_id = var.account_id

  github_repo             = var.github_repo
  github_owner            = var.github_owner
  codestar_connection_arn = var.codestar_connection_arn

  services = var.services
}

// Dev
module "vpc" {
  source              = "./modules/vpc"
  count               = terraform.workspace == "dev" ? 1 : 0
  name                = "${var.name}-vpc"
  cidr_block          = var.cidr_block
  public_subnet_cidrs = var.public_subnet_cidrs
  enable_nat_gateway  = "false"
  availability_zones = [
    "ap-southeast-1a",
    "ap-southeast-1b"
  ]
}

resource "aws_iam_role" "ec2_ecr_role" {
  count = terraform.workspace == "dev" ? 1 : 0
  name  = "${var.name}-ec2-ecr-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecr_full_access" {
  count      = terraform.workspace == "dev" ? 1 : 0
  role       = aws_iam_role.ec2_ecr_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  count = terraform.workspace == "dev" ? 1 : 0
  name  = "${var.name}-ec2-ecr-instance-profile"
  role  = aws_iam_role.ec2_ecr_role[0].name
}

module "ec2_instance" {
  count  = terraform.workspace == "dev" ? 1 : 0
  source = "terraform-aws-modules/ec2-instance/aws"

  name = "${var.name}-${terraform.workspace}"

  instance_type = "t2.medium"
  monitoring    = true
  subnet_id     = module.vpc[0].public_subnet_ids[0]

  create_iam_instance_profile = true
  iam_role_description        = "IAM role for EC2 instance to access ECR"
  iam_role_policies = {
    AmazonEC2ContainerRegistryFullAccess = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess",
    AmazonS3FullAccess                   = "arn:aws:iam::aws:policy/AmazonS3FullAccess",

  }

  iam_instance_profile = aws_iam_instance_profile.ec2_profile[0].name

  user_data = <<-EOF
                #!/bin/bash
                yum update -y
                yum install -y ruby wget

                cd /home/ec2-user
                chmod +x ./install
                wget https://aws-codedeploy-${var.region}.s3.${var.region}.amazonaws.com/latest/install
                chmod +x ./install
                ./install auto
                systemctl enable codedeploy-agent
                systemctl start codedeploy-agent

                yum install -y docker
                systemctl enable docker
                systemctl start docker
                usermod -aG docker ec2-user

                curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
                chmod +x /usr/local/bin/docker-compose
            

                docker --version
                docker-compose --version
                export REVERSE_PROXY_URL="http://$(curl -s ifconfig.me):5000"
              EOF

  tags = {
    Terraform   = "true"
    Environment = "${var.name}-codedeploy-agent"

  }
}
