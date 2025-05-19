variable "region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "ap-southeast-1"
}

variable "name" {
  description = "Name for the VPC and subnets"
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones to use for subnets"
  type        = list(string)
}

variable "environment" {
  description = "The environment for the resources"
  type        = string
  default     = "dev"
}

variable "instance_types" {
  description = "List of instance types for the EKS node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_group_size" {
  description = "Desired size of the EKS node group"
  type        = number
  default     = 2
}

variable "node_group_max_size" {
  description = "Maximum size of the EKS node group"
  type        = number
  default     = 3
}

variable "node_group_min_size" {
  description = "Minimum size of the EKS node group"
  type        = number
  default     = 1
}

variable "capacity_type" {
  description = "Capacity type for the EKS node group (ON_DEMAND or SPOT)"
  type        = string
  default     = "ON_DEMAND"
}

variable "aks_tags" {
  description = "Tags to apply to the EKS resources"
  type        = map(string)
  default     = {}
}

variable "additional_instance_types" {
  description = "Additional instance types for the EKS node group"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to the EKS node group"
  type        = map(string)
  default     = {}
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = false
}

# RDS module variables
variable "db_instance_class" {
  description = "The instance class for the RDS instance"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "The name of the database"
  type        = string
}

variable "db_port" {
  description = "The port on which the database is listening"
  type        = number
  default     = 3306
}

variable "allowed_cidr_blocks" {
  description = "The CIDR blocks that are allowed to access the RDS instance"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# CI/CD module variables
variable "github_owner" {
  description = "GitHub owner (username or organization)"
  type        = string
}

variable "codestar_connection_arn" {
  description = "ARN of the AWS CodeStar connection for GitHub"
  type        = string
}

variable "github_branch" {
  description = "GitHub branch to use for the pipeline"
  type        = string
  default     = "main"
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}

variable "cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
  default = [
    "10.0.1.0/24",
  ]
}

variable "services" {
  description = "List of services to deploy"
  type = map(object({
    image       = string
    environment = optional(map(string), {})
    port        = number
    target_port = number
  }))
}

