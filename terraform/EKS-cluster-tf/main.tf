# -------------------
# VPC
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.1"

  name = "eks-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Terraform   = "true"
    Environment = var.environment
  }
}

# EKS
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.8.5"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true
  subnet_ids  = module.vpc.private_subnets
  vpc_id      = module.vpc.vpc_id
  enable_irsa = true

  eks_managed_node_groups = {
    default_group = {
      min_size       = 2
      max_size       = 4
      desired_size   = 2
      instance_types = ["t3a.medium", "t3.medium"]
      capacity_type  = "SPOT"

      disk_size       = 20
      disk_type       = "gp3"
      disk_iops       = 3000
      disk_throughput = 125

      labels = {
        life_cycle = "spot"
      }

      tags = {
        Name        = "${var.cluster_name}-node-group"
        Environment = var.environment
      }
    }
  }

  tags = {
    Terraform   = "true"
    Environment = var.environment
  }
}

# Create an Access Entry for your IAM user
resource "aws_eks_access_entry" "admin_user" {
  depends_on = [ module.eks ]
  cluster_name  = module.eks.cluster_name
  principal_arn = var.user_arn # Your user ARN
  type          = "STANDARD" # Use "STANDARD" for IAM users and roles

  tags = {
    "Description" = "Admin access for user agtsourabh"
  }
}

# Associate the EKS Cluster Admin Policy with that Access Entry
resource "aws_eks_access_policy_association" "admin_user_policy" {
  depends_on = [ aws_eks_access_entry.admin_user ]
  cluster_name  = module.eks.cluster_name
  principal_arn = aws_eks_access_entry.admin_user.principal_arn
  policy_arn    = var.policy_arn

  access_scope {
    type = "cluster" # This policy applies to the whole cluster
  }
}

# IAM Policy for ALB Controller
data "http" "alb_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json"
}

resource "aws_iam_policy" "lb_controller_policy" {
  name   = "AWSLoadBalancerControllerIAMPolicy"
  policy = data.http.alb_policy.response_body
}

# IRSA Role binding for ALB Controller
module "lb_controller_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name                              = "${var.cluster_name}-lb-controller"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    eks = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}

# -------------------
# IAM Policy for External Secrets
data "aws_caller_identity" "current" {}

resource "aws_iam_policy" "secretsmanager_policy" {
  name        = "SolarProjectSecretsManagerPolicy"
  description = "Allow ESO to read MongoDB secret from AWS Secrets Manager"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": "arn:aws:secretsmanager:ap-south-1:${data.aws_caller_identity.current.account_id}:secret:solar-project-mongodb-creds*"
    }
  ]
}
EOF
}

module "eso_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name        = "eso-secretsmanager-role"
  role_policy_arns = { secretsmanager = aws_iam_policy.secretsmanager_policy.arn }

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["external-secrets:external-secrets"]
    }
  }
}