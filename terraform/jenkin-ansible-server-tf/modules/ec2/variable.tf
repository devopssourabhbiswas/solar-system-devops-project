variable "ami_id" {}
variable "instance_type" {}
variable "key_name" {}
variable "subnet_id" {}
variable "security_group_id" {}
variable "instance_count" {
  default = 1
}
variable "name_prefix" {
  default = "ec2"
}