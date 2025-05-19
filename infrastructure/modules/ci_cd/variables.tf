variable "services" {
  description = "List of services to deploy"
  type = map(object({
    image = string
    environment    = optional(map(string), {})
    port  = number 
    target_port = number
  }))
}

variable "codestar_connection_arn" {
  type        = string
  description = "ARN of the CodeStar connection"
}

variable "github_owner" {
  type        = string
  description = "GitHub owner (username or organization)"
}

variable "github_repo" {
  type        = string
  description = "GitHub repository name"
}

variable "region" {
  description = "The AWS region to deploy the resources"
  type        = string
  default     = "ap-southeast-1"
}

variable "name" {
  description = "The name of the project"
  type        = string
  default     = "devop-test"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    CreatedBy = "Terraform"
  }
}

variable "account_id" {
  description = "The AWS account ID"
  type        = string
}
