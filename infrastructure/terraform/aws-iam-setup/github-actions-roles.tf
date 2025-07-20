terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

variable "github_repo" {
  description = "The GitHub repository name"
  type        = string
}

variable "project_name" {
  description = "The name of the project"
  type        = string
  default     = "laravel-multi-app"
}

# OIDC Provider for GitHub Actions
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]

  tags = {
    Name = "github-actions-oidc"
  }
}

# Trust Policy for GitHub Actions
data "aws_iam_policy_document" "github_actions_assume_role" {
  statement {
    effect = "Allow"

    principals {
      identifiers = [aws_iam_openid_connect_provider.github.arn]
      type = "Federated"
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      values = ["sts.amazonaws.com"]
      variable = "token.actions.githubusercontent.com:aud"
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [
        "repo:${var.github_repo}:ref:refs/heads/development",
        "repo:${var.github_repo}:ref:refs/heads/main",
        "repo:${var.github_repo}:ref:refs/heads/production",
        "repo:${var.github_repo}:pull_request"
      ]
    }

  }
}

# GitHub Actions deployment role
resource "aws_iam_role" "github_actions_deploy" {
  name               = "GitHubActionsDeployRole"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json

  tags = {
    Name = "GitHub Actions Deploy Role"
  }
}

# ECR permissions for shared services account
data "aws_iam_policy_document" "ecr_permissions" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchImportLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
      "ecr:InitiateLayerUpload",
      "ecr:ListImages",
      "ecr:PutImage",
      "ecr:UploadLayerPart"
    ]
    resources = ["*"]
  }
}

# Terraform state access permissions
data "aws_iam_policy_document" "terraform_state_permissions" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::*-terraform-state-*",
      "arn:aws:s3:::*-terraform-state-*/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem"
    ]
    resources = [
      "arn:aws:dynamodb:*:*:table/*-terraform-lock"
    ]
  }
}

# Full infrastructure permissions for environment accounts
data "aws_iam_policy_document" "infrastructure_permissions" {
  # VPC and networking
  statement {
    effect = "Allow"
    actions = [
      "ec2:*",
      "elasticloadbalancing:*",
      "route53:*"
    ]
    resources = ["*"]
  }

  # ECS permissions
  statement {
    effect = "Allow"
    actions = [
      "ecs:*",
      "application-autoscaling:*"
    ]
    resources = ["*"]
  }

  # RDS permissions
  statement {
    effect = "Allow"
    actions = [
      "rds:*"
    ]
    resources = ["*"]
  }

  # ElastiCache permissions
  statement {
    effect = "Allow"
    actions = [
      "elasticache:*"
    ]
    resources = ["*"]
  }

  # S3 permissions
  statement {
    effect = "Allow"
    actions = [
      "s3:*"
    ]
    resources = ["*"]
  }

  # IAM permissions (limited)
  statement {
    effect = "Allow"
    actions = [
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:GetRole",
      "iam:PassRole",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:ListAttachedRolePolicies",
      "iam:PutRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:GetRolePolicy",
      "iam:ListRolePolicies",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:UpdateRole"
    ]
    resources = [
      "arn:aws:iam::*:role/${var.project_name}-*"
    ]
  }

  # CloudWatch permissions
  statement {
    effect = "Allow"
    actions = [
      "logs:*",
      "cloudwatch:*"
    ]
    resources = ["*"]
  }

  # Systems Manager permissions
  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:PutParameter",
      "ssm:DeleteParameter",
      "ssm:GetParameters",
      "ssm:DescribeParameters"
    ]
    resources = [
      "arn:aws:ssm:*:*:parameter/${var.project_name}/*"
    ]
  }

  # Secrets Manager permissions
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:CreateSecret",
      "secretsmanager:UpdateSecret",
      "secretsmanager:DeleteSecret",
      "secretsmanager:DescribeSecret"
    ]
    resources = [
      "arn:aws:secretsmanager:*:*:secret:${var.project_name}/*"
    ]
  }

  # ECR cross-account access
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage"
    ]
    resources = ["*"]
  }
}

# ECS deployment permissions (for app deployments)
data "aws_iam_policy_document" "ecs_deployment_permissions" {
  statement {
    effect = "Allow"
    actions = [
      "ecs:DescribeServices",
      "ecs:DescribeTaskDefinition",
      "ecs:DescribeTasks",
      "ecs:ListTasks",
      "ecs:RegisterTaskDefinition",
      "ecs:UpdateService",
      "ecs:ListTaskDefinitions"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "iam:PassRole"
    ]
    resources = [
      "arn:aws:iam::*:role/${var.project_name}-ecs-*"
    ]
  }
}

# Create policies
resource "aws_iam_policy" "ecr_permissions" {
  name   = "GitHubActions-ECR-Policy"
  policy = data.aws_iam_policy_document.ecr_permissions.json
}

resource "aws_iam_policy" "terraform_state_permissions" {
  name   = "GitHubActions-TerraformState-Policy"
  policy = data.aws_iam_policy_document.terraform_state_permissions.json
}

resource "aws_iam_policy" "infrastructure_permissions" {
  name   = "GitHubActions-Infrastructure-Policy"
  policy = data.aws_iam_policy_document.infrastructure_permissions.json
}

resource "aws_iam_policy" "ecs_deployment_permissions" {
  name   = "GitHubActions-ECSDeployment-Policy"
  policy = data.aws_iam_policy_document.ecs_deployment_permissions.json
}

# Attach policies to role
resource "aws_iam_role_policy_attachment" "ecr_permissions" {
  role       = aws_iam_role.github_actions_deploy.name
  policy_arn = aws_iam_policy.ecr_permissions.arn
}

resource "aws_iam_role_policy_attachment" "terraform_state_permissions" {
  role       = aws_iam_role.github_actions_deploy.name
  policy_arn = aws_iam_policy.terraform_state_permissions.arn
}

resource "aws_iam_role_policy_attachment" "infrastructure_permissions" {
  role       = aws_iam_role.github_actions_deploy.name
  policy_arn = aws_iam_policy.infrastructure_permissions.arn
}

resource "aws_iam_role_policy_attachment" "ecs_deployment_permissions" {
  role       = aws_iam_role.github_actions_deploy.name
  policy_arn = aws_iam_policy.ecs_deployment_permissions.arn
}

# Outputs
output "github_actions_role_arn" {
  description = "ARN of the GitHub Actions deployment role"
  value       = aws_iam_role.github_actions_deploy.arn
}

output "oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider"
  value       = aws_iam_openid_connect_provider.github.arn
}