terraform {
  required_version = "1.4"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

module "vpc" {
  source             = "./modules/vpc"
  vpc_cidr_block     = var.vpc_cidr_block
  public_subnet_cidr = var.public_subnet_cidr
  az_name            = var.az_name
  environment        = var.environment
  tags               = var.tags
  name_prefix        = "jenkins-ansible-server-tf"
}

module "security_group" {
  source        = "./modules/security_group"
  vpc_id        = module.vpc.vpc_id
  allowed_ports = var.allowed_ports
  environment   = var.environment
  tags          = var.tags
}

module "jenkins-main-server" {
  source            = "./modules/ec2"
  ami_id            = var.ami_id
  instance_type     = var.instance_type
  subnet_id         = module.vpc.public_subnet_id
  security_group_id = module.security_group.sg_id
  key_name          = var.key_name
  name_prefix       = "jenkins-main"
  environment       = var.environment
  root_volume_size  = var.root_volume_size
  root_volume_type  = var.root_volume_type
  user_data_script  = file("${path.module}/scripts/install_jenkins_ubuntu24.04LTS.sh")
}

/* module "ansible-controller-server" {
  source            = "./modules/ec2"
  ami_id            = var.ami_id
  instance_type     = var.instance_type
  subnet_id         = module.vpc.public_subnet_id
  security_group_id = module.security_group.sg_id
  key_name          = var.key_name
  name_prefix       = "ansible-controller"
  environment       = var.environment
  root_volume_size  = var.root_volume_size
  root_volume_type  = var.root_volume_type
  user_data_script  = file("${path.module}/scripts/install_ansible_ubuntu24.04LTS.sh")
} */
