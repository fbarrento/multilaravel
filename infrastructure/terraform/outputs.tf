# VPC Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "VPC CIDR Block"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = aws_subnet.private[*].id
}

#ECS Outputs
output "ecs_cluster_id" {
  description = "ECS Cluster ID"
  value       = aws_ecs_cluster.main.id
}

output "ecs_cluster_name" {
  description = "ECS Cluster Name"
  value       = aws_ecs_cluster.main.name
}

output "ecs_cluster_arn" {
  description = "ECS Cluster ARN"
  value       = aws_ecs_cluster.main.arn
}

# ALB Outputs
output "alb_id" {
  description = "ALB ID"
  value       = aws_alb.main.id
}

output "alb_arn" {
  description = "ALB ARN"
  value       = aws_alb.main.arn
}

output "alb_dns_name" {
  description = "ALB DNS Name"
  value       = aws_alb.main.dns_name
}

output "alb_zone_id" {
  description = "ALB Zone ID"
  value       = aws_alb.main.zone_id
}

output "alb_target_group_arn" {
  description = "ALB Target Group ARN"
  value       = aws_alb_target_group.app.arn
}


# Security Group Outputs
output "alb_security_group_id" {
  description = "ALB Security Group ID"
  value       = aws_security_group.alb.id
}

output "ecs_security_group_id" {
  description = "ECS Security Group ID"
  value       = aws_security_group.ecs_tasks.id
}

output "rds_security_group_id" {
  description = "RDS Security Group ID"
  value       = aws_security_group.rds.id
}

output "redis_security_group_id" {
  description = "Redis Security Group ID"
  value       = aws_security_group.redis.id
}

# IAM Outputs
output "ecs_task_execution_role_arn" {
  description = "ECS Task Execution Role ARN"
  value       = aws_iam_role.ecs_task_execution_role.arn
}

output "ecs_task_role_arn" {
  description = "ECS Task Role ARN"
  value       = aws_iam_role.ecs_task_role.arn
}

# ECR Outputs
output "ecr_repository_url" {
  description = "ECR Repository URL"
  value       = aws_ecr_repository.app.repository_url
}

output "ecs_repository_arn" {
  value = aws_ecr_repository.app.arn
}

# S3 Outputs
output "s3_bucket_id" {
  description = "S3 Bucket ID"
  value       = aws_s3_bucket.app_storage.id
}

output "s3_bucket_arn" {
  description = "S3 Bucket ARN"
  value       = aws_s3_bucket.app_storage.arn
}

output "s3_bucket_domain_name" {
  description = "S3 Bucket Domain Name"
  value       = aws_s3_bucket.app_storage.bucket_domain_name
}

# CloudWatch Outputs
output "cloudwatch_log_group_names" {
  description = "CloudWatch Log Group Names"
  value = {
    ecs_exec = aws_cloudwatch_log_group.ecs_exec.name
  }
}

# Application URL
output "application_url" {
  description = "Application URL"
  value       = "https://${aws_alb.main.dns_name}"
}

# Environment Information
output "environment_info" {
  description = "Environment"
  value = {
    project_name = var.project_name
    environment  = var.environment
    region       = var.aws_region
  }
}