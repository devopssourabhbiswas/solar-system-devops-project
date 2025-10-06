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

output "ebs_csi_driver_role_arn" {
  description = "EBS CSI Driver IRSA role ARN"
  value       = module.ebs_csi_driver_irsa.iam_role_arn
}

output "ebs_csi_driver_addon_status" {
  description = "EBS CSI Driver addon status"
  value       = aws_eks_addon.ebs_csi_driver.status
}

output "ebs_csi_driver_addon_version" {
  description = "EBS CSI Driver addon version"
  value       = aws_eks_addon.ebs_csi_driver.addon_version
}

output "default_storageclass" {
  description = "Default StorageClass name"
  value       = kubernetes_storage_class_v1.gp3.metadata[0].name
}

output "monitoring_storageclass" {
  description = "Monitoring StorageClass name"
  value       = kubernetes_storage_class_v1.gp3_monitoring.metadata[0].name
}

output "storage_summary" {
  description = "Storage configuration summary"
  value = {
    ebs_csi_driver = {
      status  = aws_eks_addon.ebs_csi_driver.status
      version = aws_eks_addon.ebs_csi_driver.addon_version
    }
    storageclasses = {
      default = {
        name       = kubernetes_storage_class_v1.gp3.metadata[0].name
        type       = "gp3"
        iops       = "3000"
        throughput = "125"
        reclaim    = "Retain"
      }
      monitoring = {
        name       = kubernetes_storage_class_v1.gp3_monitoring.metadata[0].name
        type       = "gp3"
        iops       = "5000"
        throughput = "250"
        reclaim    = "Retain"
      }
    }
  }
}
