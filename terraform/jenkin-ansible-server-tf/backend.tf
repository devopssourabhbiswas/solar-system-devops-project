terraform {
  backend "s3" {
    bucket         = "sourabh-terraform-state"
    key            = "jenkins-server/terraform.tfstate"
    region         = "ap-south-1"
    encrypt        = true
    use_lockfile   = true
  }
}