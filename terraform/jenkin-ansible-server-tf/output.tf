output "jenkins_instance_ids" {
  value = module.ec2.instance_ids
}

output "jenkins_public_ips" {
  value = module.ec2.public_ips
}

output "security_group_id" {
  value = module.security_group.sg_id
}

output "vpc_id" {
  value = module.vpc.vpc_id
}