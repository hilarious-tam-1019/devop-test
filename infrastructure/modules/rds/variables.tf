variable "db_name" {
  description = "The name of the database"
  type        = string
}

variable "subnet_ids" {
  description = "The list of subnet IDs for the RDS subnet group"
  type        = list(string)
}

variable "environment" {
  description = "The environment for the RDS instance (e.g., dev, prod)"
  type        = string
}

variable "vpc_id" {
  description = "The VPC ID where the RDS instance will be created"
  type        = string
}

variable "allowed_cidr_blocks" {
  description = "The CIDR blocks that are allowed to access the RDS instance"
  type        = list(string)
}

variable "db_port" {
  description = "The port on which the database is listening"
  type        = number
  default     = 5432
}

variable "db_instance_class" {
  description = "The instance class for the RDS instance"
  type        = string
  default     = "db.t3.micro"
}
