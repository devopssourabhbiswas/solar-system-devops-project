variable "aws_region" {
  type    = string
  description = "The AWS region to deploy the EKS cluster."
  default = "ap-south-1"
}

variable "profile" {
  type    = string
  description = "The AWS profile to use for authentication."
  default = "solarproj-sb"
}

variable "environment" {
  type    = string
  description = "The environment for the EKS cluster (e.g., development, staging, production)."
  default = "development"
}

variable "cluster_name" {
  type    = string
  description = "The name of the EKS cluster."
  default = "eks-cluster"
}

variable "cluster_version" {
  type    = string
  description = "The Kubernetes version for the EKS cluster."
  default = "1.32"
}

variable "user_arn" {
  type        = string
  description = "The ARN of the IAM user to grant admin access to the EKS cluster."
  default = "arn:aws:iam::847551001400:user/agtsourabh"
}

variable "role_arn" {
  type        = string
  description = "The ARN of the IAM role to grant admin access to the EKS cluster."
  default = "arn:aws:iam::847551001400:role/eksclusterrole"
}

variable "policy_arn" {
  type        = string
  description = "The ARN of the IAM policy to grant admin access to the EKS cluster."
  default = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
}


variable "ebs_csi_driver_version" {
  description = "EBS CSI Driver addon version"
  type        = string
  default     = "v1.40.0-eksbuild.1"  # Latest as of Dec 2024
}

variable "remove_existing_gp2_default" {
  description = "Remove default annotation from existing gp2 StorageClass"
  type        = bool
  default     = true
}
