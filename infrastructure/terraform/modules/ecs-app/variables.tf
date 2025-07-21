# Required Variables
variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "cluster_id" {
  description = "ID of the ECS cluster"
  type        = string
}

variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "execution_role_arn" {
  description = "ARN of the execution role"
  type        = string
}

variable "task_role_arn" {
  description = "ARN of the task role"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "subnet_ids" {
  description = "IDs of the subnets"
  type        = list(string)
}

variable "security_group_ids" {
  description = "IDs of the security groups"
  type        = list(string)
}

variable "target_group_arn" {
  description = "ARN of the ALB target group"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

# Container Configuration
variable "nginx_image" {
  description = "Nginx image"
  type        = string
  default     = "nginx:latest"
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

# Logging Configuration
variable "app_log_group_name" {
  description = "CloudWatch log group name for app container"
  type        = string
}

variable "nginx_log_group_name" {
  description = "CloudWatch log group name for nginx container"
  type        = string
}

# Service Configuration
variable "app_count" {
  description = "Number of app service tasks to run"
  type        = number
  default     = 2
}

variable "assign_pubic_ip" {
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
    "pgrep nginx"
  ]
}

variable "nginx_working_directory" {
  description = "Working directory for nginx container"
  type        = string
  default     = "/usr/share/nginx/html" # Standard nginx static content dir
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

