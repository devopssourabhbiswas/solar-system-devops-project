variable "az_name" {
  type = string
  default = "ap-south-1b"
}

variable "vpc_cidr_block" {
  type        = string
  description = "CIDR block for the VPC"
}

variable "environment" {
  type        = string
}

variable "tags" {
  type        = map(string)
}

variable "public_subnet_cidr" {
  type        = string
  description = "CIDR block for the public subnet"
}

variable "name_prefix" {
  type        = string
  description = "Prefix for naming resources"
}