output "jenkins_instance_ids" {
  value = module.jenkins-main-server.instance_ids
}

output "jenkins_public_ips" {
  value = module.jenkins-main-server.public_ips
}

output "ansible_controller_instance_ids" {
  value = module.ansible-controller-server.instance_ids
}

output "ansible_controller_public_ips" {
  value = module.ansible-controller-server.public_ips
}

output "security_group_id" {
  value = module.security_group.sg_id
}

output "vpc_id" {
  value = module.vpc.vpc_id
}