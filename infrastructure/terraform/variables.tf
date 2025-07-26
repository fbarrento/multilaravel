variable "aws_region" {
  description = "The AWS region to deploy to"
  type        = string
  default     = "eu-central-1"
}

variable "environment" {
  description = "The environment to deploy to (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "The name of the project"
  type        = string
  default     = "laravel-app"
}

# VPC Configuration
variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "The availability zones to deploy to"
  type        = list(string)
  default     = ["eu-central-1a", "eu-central-1b"]
}

variable "public_subnets_cidrs" {
  description = "The public subnets to deploy to"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets_cidrs" {
  description = "The private subnets to deploy to"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24"]
}

# ECS Configuration
variable "app_port" {
  description = "The port the app is listening on"
  type        = number
  default     = 80
}

variable "app_count" {
  description = "The number of instances to run"
  type        = number
  default     = 2
}

variable "fargate_cpu" {
  description = "Fargate instance CPU units (1024 = 1 vCPU)"
  type        = number
  default     = 1024
}

variable "fargate_memory" {
  description = "Fargate instance memory in MiB"
  type        = number
  default     = 2048
}

variable "worker_cpu" {
  description = "Fargate instance CPU units (1024 = 1 vCPU)"
  type        = number
  default     = 512
}

variable "worker_memory" {
  description = "Fargate instance memory in MiB"
  type        = number
  default     = 1024
}

variable "worker_count" {
  description = "The number of worker instances to run"
  type        = number
  default     = 1
}

# Database Configuration
variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "laravel"
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "laravel"
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "db_allocated_storage" {
  description = "Database allocated storage in GB"
  type        = number
  default     = 20
}

variable "db_backup_retention_period" {
  description = "Database backup retention period in days"
  type        = number
  default     = 7
}

variable "db_multi_az" {
  description = "Database multi availability zone"
  type        = bool
  default     = false
}

# Redis Configuration
variable "redis_node_type" {
  description = "Redis node type"
  type        = string
  default     = "cache.t3.micro"
}

variable "redis_num_cache_nodes" {
  description = "Number of cache nodes"
  type        = number
  default     = 1
}

variable "redis_parameter_group_name" {
  description = "Redis parameter group name"
  type        = string
  default     = "default.redis7"
}

variable "redis_port" {
  description = "Redis port"
  type        = number
  default     = 6379
}

# Application Configuration
variable "app_key" {
  description = "Laravel application key"
  type        = string
  sensitive   = true
}

variable "app_env" {
  description = "Laravel application environment"
  type        = string
  default     = "production"
}

variable "app_debug" {
  description = "Laravel application debug"
  type        = bool
  default     = false
}

variable "log_level" {
  description = "Laravel application log level"
  type        = string
  default     = "error"
}

# Domain Configuration

# Monitoring and Logging Configuration
variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

variable "enable_container_insights" {
  description = "Enable CloudWatch container insights"
  type        = bool
  default     = true
}

# Security Configuration
variable "enable_deletion_protection" {
  description = "Enable deletion protection for resources"
  type        = bool
  default     = false
}

# Auto Scaling Configuration
variable "enable_autoscaling" {
  description = "Enable auto scaling for ECS Services"
  type        = bool
  default     = false
}

variable "min_capacity" {
  description = "Minimum number if tasks"
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Maximum number if tasks"
  type        = number
  default     = 10
}

variable "target_cpu_utilization" {
  description = "Target CPU utilization for auto scaling"
  type        = number
  default     = 70
}

variable "target_memory_utilization" {
  description = "Target memory utilization for auto scaling"
  type        = number
  default     = 80
}

# Storage Configuration
variable "efs_performance_mode" {
  description = "EFS performance mode"
  type        = string
  default     = "generalPurpose"
}

variable "efs_throughput_mode" {
  description = "EFS throughput mode"
  type        = string
  default     = "provisioned"
}

variable "efs_provisioned_throughput" {
  description = "EFS provisioned throughput in MiB/s"
  type        = number
  default     = 100
}

# Laravel Specific Configuration
variable "queue_connection" {
  description = "Laravel queue connection"
  type        = string
  default     = "redis"
}

variable "cache_driver" {
  description = "Laravel cache driver"
  type        = string
  default     = "redis"
}

variable "session_driver" {
  description = "Laravel session driver"
  type        = string
  default     = "redis"
}

variable "broadcast_connection" {
  description = "Laravel broadcast connection"
  type        = string
  default     = "redis"
}

# Cache Configuration


# Feature Flags
variable "enable_websockets" {
  description = "Enable websockets"
  type        = bool
  default     = false
}

variable "enable_scheduler" {
  description = "Enable scheduler"
  type        = bool
  default     = false
}


# Mail Configuration
variable "mail_mailer" {
  description = "Mail driver (ses, smtp, etc.)"
  type        = string
  default     = "ses"
}

variable "mail_from_address" {
  description = "Default from email address"
  type        = string
  default     = "noreply@example.com"
}

variable "mail_from_name" {
  description = "Default from name"
  type        = string
  default     = "Laravel App"
}

# Container Image Configuration
variable "app_image" {
  description = "Docker image for the application"
  type        = string
  default     = ""
}

variable "nginx_image" {
  description = "Docker image for the nginx"
  type        = string
  default     = ""
}

variable "enable_admin_panel" {
  description = "Enable the admin panel"
  type        = bool
  default     = false
}

# Backup Configuration
variable "enable_automated_backup" {
  description = "Enable automated database backups"
  type        = bool
  default     = true
}

variable "backup_window" {
  description = "Backup window in UTC"
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "Maintenance window in UTC"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

# Cloudflare Configuration
variable "cloudflare_api_token" {
  description = "Cloudflare API token"
  type        = string
  default     = ""
}

variable "cloudflare_proxy_enabled" {
  description = "Enable Cloudflare proxy (orange cloud) for DNS records"
  type        = bool
  default     = true
}

# DNS Configuration
variable "domain_name" {
  description = "Domain name"
  type        = string
  default     = ""
}

variable "app_subdomain" {
  description = "Subdomain for the app (empty for root domain)"
  type        = string
  default     = ""
}

variable "reverb_subdomain" {
  description = "Subdomain for the reverb (empty for root domain)"
  type        = string
  default     = "multiappreverb"
}

variable "create_www_record" {
  description = "Create www record"
  type        = bool
  default     = false
}

# SSL Configuration (since Cloudflare can handle SSL)
variable "use_cloudflare_ssl" {
  description = "Use Cloudflare SSL"
  type        = bool
  default     = true
}

variable "certificate_arn" {
  description = ""
  type        = string
  default     = "ARN of the SSL certificate in ACM (optional if using Cloudflare SSL)"
}