output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  value = module.eks.cluster_security_group_id
}

output "region" {
  value = var.aws_region
}

output "argocd_alb_dns" {
  value = kubernetes_ingress_v1.argocd_ingress.status[0].load_balancer[0].ingress[0].hostname
}