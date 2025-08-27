variable "instance_count" {
  type        = number
  default     = 1
  description = "Number of EC2 instances to launch"
}

variable "ami_id" {
  type        = string
}

variable "instance_type" {
  type        = string
}

variable "key_name" {
  type        = string
}

variable "subnet_id" {
  type        = string
}

variable "security_group_id" {
  type        = string
}

variable "name_prefix" {
  type        = string
}

variable "environment" {
  type        = string
}

variable "root_volume_size" {
  type    = number
  default = 30
  
validation {
    condition     = var.root_volume_size >= 20
    error_message = "Root volume size must be at least 20 GiB."
  }


}

variable "root_volume_type" {
  type    = string
  default = "gp3"

   validation {
    condition     = var.root_volume_type == "gp3"
    error_message = "Only 'gp3' volume type is allowed for root EBS volumes."
  }
}