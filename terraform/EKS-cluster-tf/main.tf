//VPC Module
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

// EKS Cluster
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.8.5"

  cluster_name                    = var.cluster_name
  cluster_version                 = var.cluster_version
  cluster_endpoint_private_access = true                                                 // Enable private access to the cluster means control plane is accessible only within the VPC.
  cluster_endpoint_public_access  = true                                                 // Enable public access to the cluster means control plane is accessible over the internet.
  /* cluster_endpoint_public_access_cidrs = ["YOUR_OFFICE_IP/32", "VPN_PUBLIC_IP/32"] */ // Restrict public access to specific CIDR blocks (e.g., your office IP or VPN IP)
  subnet_ids  = module.vpc.private_subnets
  vpc_id      = module.vpc.vpc_id
  enable_irsa = true // Enable IAM Roles for Service Accounts

  // EKS Terraform module creates cluster IAM role automatically with policies. We don't need to create it manually.
  // EKS Terraform module also creates OIDC provider automatically if enable_irsa is true. We don't need to create it manually.
  tags = {
    Environment = var.environment
    Terraform   = "true"
  }

  eks_managed_node_groups = {
    default_group = {
      min_size     = 2
      max_size     = 4
      desired_size = 2
      /* instance_types = ["t3a.medium"] */         //Use it if using on-demand instances          
      /* capacity_type  = "ON_DEMAND" */            // Use on-demand instances
      instance_types  = ["t3a.medium", "t3.medium"] // Use it if using spot instances so that if one instance type is not available, it can use the other type.
      capacity_type   = "SPOT"                      // Use spot instances
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

      // eks managed node group on hybrid architecture

      /* eks_managed_node_groups = {
  on_demand_group = {
    min_size     = 2
    max_size     = 4
    desired_size = 2

    instance_types = ["t3a.medium"]
    capacity_type  = "ON_DEMAND"
  }

  spot_group = {
    min_size     = 2
    max_size     = 6
    desired_size = 2

    instance_types = ["t3a.medium", "t3.medium", "C5a.large"]
    capacity_type  = "SPOT"
  }
} */
    }
  }
}

// Create NameSpace for the application
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

resource "kubernetes_namespace" "production" {
  metadata {
    name = "production"
  }
}

resource "kubernetes_namespace" "development" {
  metadata {
    name = "development"
  }
}

// Deploy Argo CD in EKS Cluster
resource "helm_release" "argocd" {
  name             = "argo-cd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "5.46.7"
  namespace        = kubernetes_namespace.argocd.metadata[0].name
  create_namespace = false

  values = [
    file("${path.module}/argocd-values.yaml")
  ]
}

// Create AWS Load Balancer Controller, so that Argo CD and other applications use only one ALB to expose services. If we don't use it, each service will create its own ALB which is costly.
data "http" "alb_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json"
}

resource "aws_iam_policy" "lb_controller_policy" {
  name        = "AWSLoadBalancerControllerIAMPolicy"
  description = "Policy for AWS ALB Ingress Controller"
  policy      = data.http.alb_policy.response_body
}

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

resource "helm_release" "aws_load_balancer_controller" {
  name             = "aws-load-balancer-controller"
  repository       = "https://aws.github.io/eks-charts"
  chart            = "aws-load-balancer-controller"
  version          = "1.7.1"
  namespace        = "kube-system"
  create_namespace = false

  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }
}

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

  role_name = "eso-secretsmanager-role"

  # attach extra custom policy here
  role_policy_arns = {
   secretsmanager = aws_iam_policy.secretsmanager_policy.arn
   }

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["external-secrets:external-secrets"] # must match SA name in Helm
    }
  }
}

resource "helm_release" "external_secrets" {
  name             = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  version          = "0.9.13"
  namespace        = "external-secrets"
  create_namespace = true

  set {
    name  = "serviceAccount.name"
    value = "external-secrets"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.eso_irsa_role.iam_role_arn
  }
}


resource "kubernetes_manifest" "cluster_secretstore" {
  manifest = {
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ClusterSecretStore"
    metadata = {
      name = "aws-secretsmanager"
    }
    spec = {
      provider = {
        aws = {
          service = "SecretsManager"
          region  = "ap-south-1"
          auth = {
            jwt = {
              serviceAccountRef = {
                name      = "external-secrets"
                namespace = "external-secrets"
              }
            }
          }
        }
      }
    }
  }
}