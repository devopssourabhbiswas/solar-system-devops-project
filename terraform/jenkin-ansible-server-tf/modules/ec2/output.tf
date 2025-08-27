output "instance_ids" {
  description = "The IDs of all the EC2 instances"
  value       = aws_instance.ec2[*].id
}