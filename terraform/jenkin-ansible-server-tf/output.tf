output "jenkins_instance_id" {
  value = module.ec2.instance_id
}

output "jenkins_public_ip" {
  value = module.ec2.public_ip
}

output "security_group_id" {
  value = module.security_group.sg_id
}

output "vpc_id" {
  value = module.vpc.vpc_id
}