output "cluster_name" {
  description = "The name of the EKS cluster."
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "The endpoint URL of the EKS cluster."
  value = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "The security group ID of the EKS cluster."
  value = module.eks.cluster_security_group_id
}

output "region" {
  description = "The AWS region where the EKS cluster is deployed."
  value = var.aws_region
}

output "lb_controller_role_arn" {
  description = "The ARN of the IAM role for the AWS Load Balancer Controller."
  value       = module.lb_controller_irsa.iam_role_arn
}