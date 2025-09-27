terraform {
  backend "s3" {
    bucket         = "sourabhdevops-terraform-state"
    key            = "eks-cluster/terraform.tfstate"
    region         = "ap-south-1"
    encrypt        = true
    use_lockfile   = true
  }
}