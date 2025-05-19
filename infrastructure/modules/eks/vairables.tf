variable "name" {
  description = "The name of the cluster"
  type        = string
}

variable "node_group_name" {
  description = "The name of the node group"
  type        = string
}

variable "instance_types" {
  description = "The list of instance types"
  type        = list(string)
}

variable "node_group_size" {
  description = "The desired size of the node group"
  type        = number
}

variable "node_group_max_size" {
  description = "The maximum size of the node group"
  type        = number
}

variable "node_group_min_size" {
  description = "The minimum size of the node group"
  type        = number
}

variable "additional_instance_types" {
  description = "The list of additional instance types"
  type        = list(string)
}

variable "capacity_type" {
  description = "The capacity type of the node group"
  type        = string
}

variable "tags" {
  description = "The tags to apply to the node group"
  type        = map(string)
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
    "10.0.2.0/24"
  ]
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets"
  type        = list(string)
  default = [
    "10.0.101.0/24",
    "10.0.102.0/24"
  ]
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
}

variable "availability_zones" {
  description = "List of availability zones to use for subnets"
  type        = list(string)
}

variable "environment" {
  description = "The environment for the resources"
  type        = string
}


