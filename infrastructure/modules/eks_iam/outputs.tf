output "eks_role_arn" {
  description = "ARN of the IAM role for EKS"
  value       = aws_iam_role.eks_role.arn
}

output "eks_policy_arn" {
  description = "ARN of the IAM policy for EKS"
  value       = aws_iam_policy.eks_policy.arn
}

output "eks_node_group_role_arn" {
  description = "ARN of the IAM role for EKS node group"
  value       = aws_iam_role.eks_node_group_role.arn
}

