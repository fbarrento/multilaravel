# Required Variables
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = null
}

variable "cluster_id" {
  description = "ID of the ECS cluster"
  type        = string
  default     = null
}

variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
  default     = null
}

variable "execution_role_arn" {
  description = "ARN of the execution role"
  type        = string
  default     = null
}

variable "task_role_arn" {
  description = "ARN of the task role"
  type        = string
  default     = null
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "IDs of the subnets"
  type        = list(string)
}

variable "security_group_ids" {
  description = "IDs of the security groups"
  type        = list(string)
}

variable "app_target_group_arn" {
  description = "ARN of the ALB target group for app service"
  type        = string
}

variable "reverb_target_group_arn" {
  description = "ARN of the ALB target group for reverb service"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "services" {
  description = "Map of services to deploy with their configurations"
  type = map(object({
    cpu                       = number
    memory                    = number
    desired_count             = number
    health_check_grace_period = optional(number, 300)
    autoscaling_enabled       = optional(bool, false)
    min_capacity              = optional(number, 1)
    max_capacity              = optional(number, 10)
    target_cpu_utilization    = optional(number, 70)
    target_memory_utilization = optional(number, 70)
    additional_environment = optional(list(object({
      name  = string
      value = string
    })), [])
    additional_secrets = optional(list(object({
      name      = string
      valueFrom = string
    })))
  }))
}

# Container Configuration
variable "nginx_image" {
  description = "Nginx image"
  type        = string
  default     = "nginx:latest"
}

variable "app_image" {
  description = "Docker image for the Laravel application"
  type        = string
}


# Application Configuration
variable "app_env" {
  description = "Laravel application environment name"
  type        = string
}

variable "app_debug" {
  description = "Laravel application debug mode"
  type        = bool
}

variable "app_key" {
  description = "Laravel application key"
  type        = string
  sensitive   = true
}


# Session Configuration
variable "session_driver" {
  description = "Laravel session driver"
  type        = string
  default     = "redis"
}

variable "session_domain" {
  description = "Laravel session domain"
  type        = string
  default     = ""
}

variable "queue_connection" {
  description = "Laravel queue connection"
  type        = string
  default     = "redis"
}

# Database Configuration
variable "db_connection" {
  description = "Database connection"
  type        = string
  default     = "mysql"
}
variable "db_host" {
  description = "Database host (used when create_rds_data_source if false)"
  type        = string
  default     = ""
}

variable "db_name" {
  description = "Database name (used when create_rds_data_source if false)"
  type        = string
}

variable "db_port" {
  description = "Database port (used when create_rds_data_source if false)"
  type        = number
  default     = 3306
}

variable "db_username" {
  description = "Database username"
  type        = string
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
  default     = ""
}

variable "db_password_parameter_arn" {
  description = "ARN of the parameter store for the database password"
  type        = string
}

# Cache Configuration
variable "cache_store" {
  description = "Cache store"
  type        = string
  default     = "redis"
}

variable "cache_driver" {
  description = "Laravel cache driver"
  type        = string
  default     = "redis"
}

# Redis Configuration
variable "redis_host" {
  description = "Redis host"
  type        = string
}

variable "redis_port" {
  description = "Redis port"
  type        = number
  default     = 6379
}

variable "redis_password" {
  description = "Redis password"
  type        = string
  sensitive   = true
  default     = ""
}

variable "redis_password_parameter_arn" {
  description = "ARN of the parameter store for the Redis password"
  type        = string
}

variable "redis_scheme" {
  description = "Redis scheme tls or tcp (default: tls)"
  type        = string
  default     = "tls"
}

variable "redis_cache_db" {
  description = "Redis cache database"
  type        = number
  default     = 1
}

variable "redis_db" {
  description = "Redis database"
  type        = number
  default     = 0
}

variable "redis_client" {
  description = "Redis client"
  type        = string
  default     = "phpredis"
}

# Broadcaster Configuration
variable "broadcast_connection" {
  description = "Broadcaster connection"
  type        = string
  default     = "reverb"
}

variable "reverb_host" {
  description = "Reverb host"
  type        = string
}

variable "reverb_port" {
  description = "Reverb port"
  type        = number
  default     = 443
}

variable "reverb_scheme" {
  description = "Reverb scheme"
  type        = string
  default     = "https"
}

# Logging Configuration
variable "log_retention_days" {
  description = "Log retention days"
  type        = number
  default     = 7
}

variable "log_channel" {
  description = "Log channel for Laravel"
  type        = string
  default     = "stderr"
}

variable "log_level" {
  description = "Laravel application log level"
  type        = string
  default     = "error"
}

variable "log_stderr_formatter" {
  description = "Laravel application log stderr formatter"
  type        = string
  default     = "json"
}


# Service Configuration
variable "app_count" {
  description = "Number of app service tasks to run"
  type        = number
  default     = 2
}

variable "assign_public_ip" {
  description = "Assign a public IP address to the task"
  type        = bool
  default     = false
}

variable "platform_version" {
  description = "Fargate platform version"
  type        = string
  default     = "LATEST"
}

variable "enable_execute_command" {
  description = "Enable Fargate execute command for debugging"
  type        = bool
  default     = false
}

# Health Check Configuration
variable "health_check_grace_period" {
  description = "Health check grace period in seconds"
  type        = number
  default     = 300
}

variable "health_check_interval" {
  description = "Health check interval in seconds"
  type        = number
  default     = 30
}

variable "health_check_timeout" {
  description = "Health check timeout in seconds"
  type        = number
  default     = 5
}

variable "health_check_retries" {
  description = "Health check retries"
  type        = number
  default     = 3
}

variable "health_check_start_period" {
  description = "Health check start period in seconds"
  type        = number
  default     = 60
}

variable "nginx_health_check_command" {
  description = "Health check command for nginx container"
  type        = list(string)
  default = [
    "CMD-SHELL",
    "curl -f http://localhost/ || exit 1"
  ]
}

variable "nginx_working_directory" {
  description = "Working directory for nginx container"
  type        = string
  default     = "/usr/share/nginx/html" # Standard nginx static content dir
}

variable "php_health_check_command" {
  description = "Health check command for app container"
  type        = list(string)
  default = [
    "CMD-SHELL",
    "php -v && test -f /var/www/main/vendor/autoload.php"
  ]
}

variable "php_working_directory" {
  description = "Working directory for app container"
  type        = string
  default     = "/var/www/main"
}



# Auto Scaling Configuration
variable "autoscaling_enabled" {
  description = "Enable auto scaling for ECS Service"
  type        = bool
  default     = false
}

variable "min_capacity" {
  description = "Minimum number of tasks"
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Maximum number of tasks"
  type        = number
  default     = 10
}

variable "target_cpu_utilization" {
  description = "Target CPU utilization"
  type        = number
  default     = 70
}

variable "target_memory_utilization" {
  description = "Target memory utilization"
  type        = number
  default     = 70
}

variable "scale_in_cooldown" {
  description = "Scale in cooldown period in seconds"
  type        = number
  default     = 300
}

variable "scale_out_cooldown" {
  description = "Scale out cooldown period in seconds"
  type        = number
  default     = 300
}

# Service Discovery Configuration
variable "create_service_discovery" {
  description = "Create Service Discovery namespace"
  type        = bool
  default     = true
}

# Additional Environment Variables
variable "additional_environment_variables" {
  description = "Additional environment variables for the app container"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

# Tags
variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}

