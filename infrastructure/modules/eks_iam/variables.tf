variable "role_name" {
  description = "The name of the IAM role to create"
  type        = string
  default     = "eks-cluster-role"
}

variable "policy_name" {
  description = "The name of the IAM policy to create"
  type        = string
  default     = "eks-policy"
}
