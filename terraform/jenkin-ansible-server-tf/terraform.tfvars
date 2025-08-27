vpc_cidr_block = "10.0.0.0/16"
ami_id         = "ami-0abcdef1234567890"
instance_type  = "t3.micro"
key_name       = "jenkins-server-solar-sys-key"
allowed_ports  = [22, 8080]
environment    = "dev"
az_name        = "ap-south-1a"

tags = {
  Project     = "SolarSystem"
  Owner       = "Sourabh"
  Environment = "dev"
}