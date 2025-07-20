terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type    = string
  default = "eu-central-1"
}

variable "organization_name" {
  description = "The name of the organization"
  type        = string
  default     = "between"
}

variable "project_name" {
  description = "The name of the project"
  type        = string
  default     = "laravel-multi-app"
}

# Random suffix for bucket uniqueness
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "${var.organization_name}-${var.project_name}-terraform-state-${random_string.bucket_suffix.result}"
  tags = {
    Name        = "Terraform State Bucket"
    Project     = var.project_name
    Environment = "shared"
    Purpose     = "terraform-state"
  }
}

# Enable versioning
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# DynamoDB table for state locking
resource "aws_dynamodb_table" "terraform_lock" {
  name         = "${var.organization_name}-${var.project_name}-terraform-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "Terraform Lock Table"
    Project     = var.project_name
    Environment = "shared"
    Purpose     = "terraform-lock"
  }
}

# Outputs for use in CI/CD
output "terraform_state_bucket" {
  description = "S3 bucket name for Terraform state"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "terraform_lock_table" {
  description = "DynamoDB table name for Terraform state locking"
  value       = aws_dynamodb_table.terraform_lock.name
}

output "setup_commands" {
  description = "Commands to set up GitHub secrets"
  value = {
    state_bucket = "gh secret set TERRAFORM_STATE_BUCKET --body '${aws_s3_bucket.terraform_state.bucket}'"
    lock_table   = "gh secret set TERRAFORM_LOCK_TABLE --body '${aws_dynamodb_table.terraform_lock.name}'"
  }
}