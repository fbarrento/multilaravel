# Development environment configuration

# Basic Configuration
project_name = "laravel-app"
environment  = "development"
aws_region   = "eu-central-1"

# Network Configuration
vpc_cidr              = "10.0.0.0/16"
availability_zones    = ["eu-central-1a", "eu-central-1b"]
public_subnets_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnets_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]

# Database Configuration
db_instance_class          = "db.t3.micro"
db_name                    = "laravel_development"
db_username                = "laravel_development"
db_allocated_storage       = 20
db_backup_retention_period = 7
db_multi_az                = false

# Redis Configuration
redis_node_type       = "cache.t3.micro"
redis_num_cache_nodes = 1

# ECS Configuration
app_count      = 2
fargate_cpu    = 1024
fargate_memory = 2048
worker_count   = 1
worker_cpu     = 1
worker_memory  = 1024

# ECS Auto Scaling Configuration
enable_autoscaling        = true
min_capacity              = 1
max_capacity              = 5
target_cpu_utilization    = 70
target_memory_utilization = 80

# Application Configuration
app_key   = "base64:DEV_KEY_HERE_1234567890abcdefghijklmnopqrstuvwxyz="
app_env   = "development"
app_debug = true
log_level = "info"

# Feature Flags
enable_websockets          = true
enable_scheduler           = true
enable_deletion_protection = false

# Monitoring Configuration
log_retention_days        = 7
enable_container_insights = true

# Backup Configuration
enable_automated_backup = true
backup_window           = "03:00-04:00"
maintenance_window      = "sun:04:00-sun:05:00"

# Mail Configuration
mail_mailer       = "ses"
mail_from_address = "hello@example.com"
mail_from_name    = "Laravel App"

# Laravel Drivers
queue_connection     = "redis"
cache_driver         = "redis"
session_driver       = "redis"
broadcast_connection = "reverb"

# Domain Configuration (empty for development)
domain_name = ""

# Container Images (will be updated by CI/CD)
app_image   = "859702631282.dkr.ecr.us-east-1.amazonaws.com/between/laravel-app:development-latest"
nginx_image = "nginx:alpine"