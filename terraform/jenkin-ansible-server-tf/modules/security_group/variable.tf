variable "vpc_id" {
  type        = string
  description = "VPC ID to attach the security group"
}

variable "allowed_ports" {
  type        = map(number)
  description = "Map of allowed ports"
}

variable "environment" {
  type        = string
}

variable "tags" {
  type        = map(string)
}