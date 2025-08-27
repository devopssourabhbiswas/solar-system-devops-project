terraform {
  required_version = "1.13"
  required_providers {
  aws = {
    source  = "hashicorp/aws"
    version = "~> 5.0"
  }
}
}

resource "aws_s3_bucket" "tf-state-lock" {
  bucket = var.bucket_name
  tags = {
    Name = "solarproj"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_versioning" "tf_state_versioning" {
  bucket = aws_s3_bucket.tf-state-lock.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_ownership_controls" "tf_state_ownership" {
  bucket = aws_s3_bucket.tf-state-lock.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "tf_state_access_block" {
  bucket                  = aws_s3_bucket.tf-state-lock.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_acl" "tf_state_acl" {
  bucket = aws_s3_bucket.tf-state-lock.id
  acl    = "private"

  depends_on = [
    aws_s3_bucket_ownership_controls.tf_state_ownership,
    aws_s3_bucket_public_access_block.tf_state_access_block
  ]
}

resource "aws_dynamodb_table" "tf_lock" {
  name         = var.lock_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "Terraform Lock Table"
    Environment = var.environment
  }
}

