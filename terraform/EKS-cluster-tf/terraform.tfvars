aws_region      = "ap-south-1"
profile         = "solarproj-sb"
environment     = "production"
cluster_name    = "solar-project-eks-cluster"
cluster_version = "1.33"
user_arn        = "arn:aws:iam::847551001400:user/agtsourabh" # Replace with your IAM user ARN
role_arn        = "arn:aws:iam::847551001400:role/eksclusterrole" # Replace with your IAM role ARN
policy_arn      = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy" # EKS Cluster Admin Policy ARN