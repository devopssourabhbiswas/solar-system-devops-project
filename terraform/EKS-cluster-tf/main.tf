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

  enable_dns_hostnames = true
  enable_dns_support   = true
  
  # Tag for VPC.
  tags = {
    Terraform   = "true"
    Environment = var.environment
  }

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
    Associatedwith = var.cluster_name
    Type = "public"
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
    Associatedwith = var.cluster_name
    Type = "private"
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
      min_size       = var.node_min_size
      max_size       = var.node_max_size
      desired_size   = var.node_desired_size
      instance_types = var.node_instance_types
      capacity_type  = var.node_capacity_type # "ON_DEMAND" or "SPOT"

      /* disk_size       = var.disk_size */ # Because AMI is not mentioned, it uses default disk size of 20 GB
      disk_type       = var.disk_type
      disk_iops       = var.disk_iops
      disk_throughput = var.disk_throughput

      labels = {
        life_cycle = var.node_capacity_type == "SPOT" ? "spot" : "on-demand"
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


# EBS CSI Driver - IAM Policy
resource "aws_iam_policy" "ebs_csi_driver" {
  name        = "${var.cluster_name}-ebs-csi-driver-policy"
  description = "IAM policy for EBS CSI Driver"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateSnapshot",
          "ec2:AttachVolume",
          "ec2:DetachVolume",
          "ec2:ModifyVolume",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeInstances",
          "ec2:DescribeSnapshots",
          "ec2:DescribeTags",
          "ec2:DescribeVolumes",
          "ec2:DescribeVolumesModifications"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateTags"
        ]
        Resource = [
          "arn:aws:ec2:*:*:volume/*",
          "arn:aws:ec2:*:*:snapshot/*"
        ]
        Condition = {
          StringEquals = {
            "ec2:CreateAction" = [
              "CreateVolume",
              "CreateSnapshot"
            ]
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DeleteTags"
        ]
        Resource = [
          "arn:aws:ec2:*:*:volume/*",
          "arn:aws:ec2:*:*:snapshot/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateVolume"
        ]
        Resource = "*"
        Condition = {
          StringLike = {
            "aws:RequestTag/ebs.csi.aws.com/cluster" = "true"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateVolume"
        ]
        Resource = "*"
        Condition = {
          StringLike = {
            "aws:RequestTag/CSIVolumeName" = "*"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DeleteVolume"
        ]
        Resource = "*"
        Condition = {
          StringLike = {
            "ec2:ResourceTag/ebs.csi.aws.com/cluster" = "true"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DeleteVolume"
        ]
        Resource = "*"
        Condition = {
          StringLike = {
            "ec2:ResourceTag/CSIVolumeName" = "*"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DeleteVolume"
        ]
        Resource = "*"
        Condition = {
          StringLike = {
            "ec2:ResourceTag/kubernetes.io/created-for/pvc/name" = "*"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DeleteSnapshot"
        ]
        Resource = "*"
        Condition = {
          StringLike = {
            "ec2:ResourceTag/CSIVolumeSnapshotName" = "*"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DeleteSnapshot"
        ]
        Resource = "*"
        Condition = {
          StringLike = {
            "ec2:ResourceTag/ebs.csi.aws.com/cluster" = "true"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "${var.cluster_name}-ebs-csi-driver-policy"
    Environment = var.environment
  }
}

# EBS CSI Driver - IRSA Role
module "ebs_csi_driver_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name             = "${var.cluster_name}-ebs-csi-driver-role"
  attach_ebs_csi_policy = true
  
  # Attach our custom policy
  role_policy_arns = {
    ebs_csi = aws_iam_policy.ebs_csi_driver.arn
  }

  oidc_providers = {
    eks = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  tags = {
    Name        = "${var.cluster_name}-ebs-csi-driver-role"
    Environment = var.environment
  }
}

# EBS CSI Driver - EKS Addon
resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name             = module.eks.cluster_name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = var.ebs_csi_driver_version
  service_account_role_arn = module.ebs_csi_driver_irsa.iam_role_arn
  
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = {
    Name        = "${var.cluster_name}-ebs-csi-driver-addon"
    Environment = var.environment
  }

  depends_on = [
    module.ebs_csi_driver_irsa
  ]
}

# StorageClass - GP3 (Default)
resource "kubernetes_storage_class_v1" "gp3" {
  metadata {
    name = "gp3"
    
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
    
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/component"  = "storage"
    }
  }

  storage_provisioner    = "ebs.csi.aws.com"
  reclaim_policy         = "Retain"
  allow_volume_expansion = true
  volume_binding_mode    = "WaitForFirstConsumer"

  parameters = {
    type      = "gp3"
    encrypted = "true"
    "csi.storage.k8s.io/fstype" = "ext4"
    iops      = "3000"
    throughput = "125"
    
    # Tags for EBS volumes
    tagSpecification_1 = "Name={{ .PVCNamespace }}/{{ .PVCName }}"
    tagSpecification_2 = "Project=solar-project"
    tagSpecification_3 = "ManagedBy=terraform"
    tagSpecification_4 = "Environment=${var.environment}"
  }

  depends_on = [
    aws_eks_addon.ebs_csi_driver
  ]
}

# StorageClass - GP3 Monitoring (High Performance)
resource "kubernetes_storage_class_v1" "gp3_monitoring" {
  metadata {
    name = "gp3-monitoring"
    
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "false"
    }
    
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/component"  = "storage"
      "app.kubernetes.io/part-of"    = "monitoring"
    }
  }

  storage_provisioner    = "ebs.csi.aws.com"
  reclaim_policy         = "Retain" # Other option is Delete. Choose Retain to keep data even if PVC is deleted.
  allow_volume_expansion = true
  volume_binding_mode    = "WaitForFirstConsumer"

  parameters = {
    type      = "gp3"
    encrypted = "true"
    "csi.storage.k8s.io/fstype" = "ext4"
    iops      = "2500"      # Higher IOPS for monitoring also depends on volume size. Always check altermanager pvc requests. Calculate like 500 IOPS for 1GB volume
    throughput = "250"       # Higher throughput for monitoring
    
    # Tags
    tagSpecification_1 = "Name={{ .PVCNamespace }}/{{ .PVCName }}"
    tagSpecification_2 = "Project=solar-project"
    tagSpecification_3 = "ManagedBy=terraform"
    tagSpecification_4 = "Environment=${var.environment}"
    tagSpecification_5 = "Component=monitoring"
  }

  depends_on = [
    aws_eks_addon.ebs_csi_driver
  ]
}

# Optional: Remove default annotation from existing gp2
resource "null_resource" "remove_gp2_default" {
  count = var.remove_existing_gp2_default ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.aws_region}
      kubectl annotate storageclass gp2 storageclass.kubernetes.io/is-default-class=false --overwrite 2>/dev/null || true
    EOT
  }

  depends_on = [
    kubernetes_storage_class_v1.gp3
  ]
}