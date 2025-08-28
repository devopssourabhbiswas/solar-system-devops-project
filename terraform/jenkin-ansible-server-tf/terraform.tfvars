vpc_cidr_block = "10.0.0.0/16"
ami_id         = "ami-02d26659fd82cf299" # Ubuntu 24.04 LTS - ap-south-1
instance_type  = "t3.small"
key_name       = "jenkins-server-solar-sys-key"
allowed_ports = {
  ssh     = 22
  http    = 80
  https   = 443
  jenkins = 8080
}
environment    = "dev"
az_name        = "ap-south-1a"
name_prefix    = "jenkins-main-server"
public_subnet_cidr = "10.0.1.0/24"
root_volume_size = 25
root_volume_type = "gp3"

tags = {
  Project     = "SolarSystem"
  Owner       = "Sourabh"
  Environment = "dev"
}