variable "vpc_cidr_block" {
  type        = string
  description = "CIDR block for the VPC"
}

variable "ami_id" {
  type        = string
  description = "AMI ID for Jenkins EC2 instance"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
}

variable "key_name" {
  type        = string
  description = "SSH key name for EC2 access"
}

variable "allowed_ports" {
  type        = map(number)
  description = "Map of allowed ports for security group"
}

variable "environment" {
  type        = string
  description = "Environment name (e.g., dev, prod)"
}

variable "tags" {
  type        = map(string)
  description = "Common tags for all resources"
}

variable "az_name" {
  type        = string
  description = "Availability zone for the EC2 instance"
  default     = "ap-south-1b"
}

variable "root_volume_size" {
  type    = number
  default = 30
}

variable "root_volume_type" {
  type    = string
}

variable "public_subnet_cidr" {
  type        = string
  description = "CIDR block for the public subnet"
}
variable "name_prefix" {
  type        = string
  description = "Prefix for naming resources"
  default     = "jenkins-main"
}