resource "aws_instance" "ec2" {
  count                  = var.instance_count
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  user_data              = var.user_data_script


  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = var.root_volume_type
    delete_on_termination = true
    encrypted             = true

  }

  tags = {
    Name        = "${var.name_prefix}-${count.index + 1}"
    Environment = var.environment
    Project     = "SolarSystem"
  }
}
