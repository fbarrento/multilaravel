resource "aws_ssm_parameter" "app_key" {
  name  = "/${var.project_name}/${var.app_env}/app/key"
  type  = "SecureString"
  value = var.app_key

  tags = {
    Name = "${var.project_name}-app-key"
  }
}

# Service Discovery Namespace
resource "aws_service_discovery_private_dns_namespace" "main" {
  count       = var.create_service_discovery ? 1 : 0
  name        = "${var.project_name}.local"
  description = "Private DNS namespace for ${var.project_name}"
  vpc         = var.vpc_id

  tags = var.tags
}

# Service Discovery Service
resource "aws_service_discovery_service" "services" {
  for_each = var.create_service_discovery ? var.services : {}
  name     = each.key

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main[0].id
    dns_records {
      ttl  = 10
      type = "A"
    }
    routing_policy = "MULTIVALUE"
  }

  tags = var.tags
}

locals {
  base_environment = [
    {
      name  = "APP_ENV"
      value = tostring(var.app_env)
    },
    {
      name  = "APP_DEBUG"
      value = tostring(var.app_debug)
    },
    {
      name  = "LOG_LEVEL"
      value = tostring(var.log_level)
    },
    {
      name  = "DB_HOST"
      value = tostring(var.db_host)
    },
    {
      name  = "DB_PORT"
      value = tostring(var.db_port)
    },
    {
      name  = "DB_CONNECTION"
      value = tostring(var.db_connection)
    },
    {
      name  = "DB_DATABASE"
      value = tostring(var.db_name)
    },
    {
      name  = "DB_USERNAME"
      value = tostring(var.db_username)
    },
    {
      name  = "REDIS_HOST"
      value = tostring(var.redis_host)
    },
    {
      name  = "REDIS_PORT"
      value = tostring(var.redis_port)
    },
    {
      name  = "REDIS_SCHEME"
      value = tostring(var.redis_scheme)
    },
    {
      name  = "REDIS_CACHE_DB"
      value = tostring(var.redis_cache_db)
    },
    {
      name  = "REDIS_DB"
      value = tostring(var.redis_db)
    },
    {
      name  = "REDIS_CLIENT"
      value = tostring(var.redis_client)
    },
    {
      name  = "LOG_CHANNEL"
      value = tostring(var.log_channel)
    },
    {
      name  = "LOG_STDERR_FORMATTER"
      value = tostring(var.log_stderr_formatter)
    },
    {
      name  = "CACHE_STORE"
      value = tostring(var.cache_store)
    },
    {
      name  = "QUEUE_CONNECTION"
      value = tostring(var.queue_connection)
    },
    {
      name  = "SESSION_DRIVER"
      value = tostring(var.session_driver)
    },
    {
      name  = "SESSION_DOMAIN"
      value = tostring(var.session_domain)
    },
    {
      name  = "BROADCAST_CONNECTION"
      value = tostring(var.broadcast_connection)
    },
    {
      name  = "REVERB_HOST"
      value = tostring(var.reverb_host)
    },
    {
      name  = "REVERB_PORT"
      value = tostring(var.reverb_port)
    },
    {
      name  = "REVERB_SCHEME"
      value = tostring(var.reverb_scheme)
    }
  ]

  base_secrets = [
    for secret in [
      {
        name      = "APP_KEY"
        valueFrom = aws_ssm_parameter.app_key.arn
      },
      var.db_password_parameter_arn != null && var.db_password_parameter_arn != "" ? {
        name      = "DB_PASSWORD"
        valueFrom = var.db_password_parameter_arn
      } : null,
      var.redis_password_parameter_arn != null && var.redis_password_parameter_arn != "" ? {
        name      = "REDIS_PASSWORD"
        valueFrom = var.redis_password_parameter_arn
      } : null
    ] : secret if secret != null
  ]

  # Helper functions to safely get additional variables
  get_additional_environment = {
    for service_name, service_config in var.services :
    service_name => try(service_config.additional_environment, [])
  }

  get_additional_secrets = {
    for service_name, service_config in var.services :
    service_name => try(service_config.additional_secrets, [])
  }
}

# ECS Task Definition
resource "aws_ecs_task_definition" "services" {
  for_each = var.services

  family                   = "${var.project_name}-${each.key}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = each.value.cpu
  memory                   = each.value.memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode(concat([
    # Main app container - always present
    {
      name      = "app"
      image     = var.app_image
      essential = true

      environment = concat(
        local.base_environment,
        [
          {
            name  = "APP_NAME"
            value = var.project_name
          },
          {
            name  = "CONTAINER_ROLE"
            value = each.key
          }
        ],
        local.get_additional_environment[each.key]
      )

      secrets = concat(
        local.base_secrets,
        local.get_additional_secrets[each.key]
      )

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.services[each.key].name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      workingDirectory = var.php_working_directory

      # Conditional port mappings
      portMappings = each.key == "app" ? [
        {
          containerPort = 9000
          protocol      = "tcp"
        }
        ] : each.key == "reverb" ? [
        {
          containerPort = var.reverb_port
          protocol      = "tcp"
        }
      ] : []

      # Conditional health checks
      healthCheck = each.key == "app" ? {
        command     = var.php_health_check_command
        interval    = var.health_check_interval
        timeout     = var.health_check_timeout
        retries     = var.health_check_retries
        startPeriod = 30
        } : each.key == "reverb" ? {
        command     = ["CMD-SHELL", "curl -f http://localhost:${var.reverb_port}/health || exit 1"]
        interval    = var.health_check_interval
        timeout     = var.health_check_timeout
        retries     = var.health_check_retries
        startPeriod = 60
        } : contains(["worker", "scheduler", "horizon"], each.key) ? {
        command     = ["CMD-SHELL", "ps aux | grep -E '(queue:work|schedule:run|horizon)' | grep -v grep || exit 1"]
        interval    = var.health_check_interval
        timeout     = var.health_check_timeout
        retries     = var.health_check_retries
        startPeriod = 60
        } : {
        command     = ["CMD-SHELL", "php -v || exit 1"]
        interval    = var.health_check_interval
        timeout     = var.health_check_timeout
        retries     = var.health_check_retries
        startPeriod = 60
      }
    }
    ],

    # Nginx container - only for app service
    each.key == "app" ? [
      {
        name      = "nginx"
        image     = var.nginx_image
        essential = true

        portMappings = [
          {
            containerPort = 80
            protocol      = "tcp"
          }
        ]

        dependsOn = [
          {
            containerName = "app"
            condition     = "HEALTHY"
          }
        ]

        healthCheck = {
          command     = var.nginx_health_check_command
          interval    = var.health_check_interval
          timeout     = var.health_check_timeout
          retries     = var.health_check_retries
          startPeriod = 30
        }

        logConfiguration = {
          logDriver = "awslogs"
          options = {
            "awslogs-group"         = aws_cloudwatch_log_group.nginx[0].name
            "awslogs-region"        = var.aws_region
            "awslogs-stream-prefix" = "ecs"
          }
        }

        workingDirectory = var.nginx_working_directory
      }
    ] : []
  ))

  tags = var.tags
}

# CloudWatch Log Group for services
resource "aws_cloudwatch_log_group" "services" {
  for_each = var.services

  name              = "/ecs/${var.project_name}/${each.key}"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Name = "${var.project_name}-${each.key}-logs"
  })
}

# Nginx log group (only created for app service)
resource "aws_cloudwatch_log_group" "nginx" {
  count = contains(keys(var.services), "app") ? 1 : 0

  name              = "/ecs/${var.project_name}/nginx"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Name = "${var.project_name}-nginx-logs"
  })
}

# ECS Service
resource "aws_ecs_service" "services" {
  for_each = var.services

  name            = "${var.project_name}-${each.key}"
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.services[each.key].arn
  desired_count   = each.value.desired_count
  launch_type     = "FARGATE"

  force_new_deployment   = true
  enable_execute_command = var.enable_execute_command

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = var.security_group_ids
    assign_public_ip = var.assign_public_ip
  }

  dynamic "load_balancer" {
    for_each = each.key == "app" ? [1] : []
    content {
      container_name   = "nginx"
      container_port   = 80
      target_group_arn = var.app_target_group_arn
    }
  }

  dynamic "load_balancer" {
    for_each = each.key == "reverb" ? [1] : []
    content {
      container_name   = "app"
      container_port   = var.reverb_port
      target_group_arn = var.reverb_target_group_arn
    }
  }

  health_check_grace_period_seconds = lookup(each.value, "health_check_grace_period", var.health_check_grace_period)

  # Service Discovery
  dynamic "service_registries" {
    for_each = var.create_service_discovery ? [1] : []
    content {
      registry_arn = aws_service_discovery_service.services[each.key].arn
    }
  }

  # Auto Scaling
  lifecycle {
    ignore_changes = [desired_count]
  }

  platform_version = var.platform_version

  tags = var.tags
}

# Auto Scaling Target
resource "aws_appautoscaling_target" "services" {
  for_each = {
    for k, v in var.services : k => v
    if lookup(v, "autoscaling_enabled", false)
  }

  max_capacity       = each.value.max_capacity
  min_capacity       = each.value.min_capacity
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.services[each.key].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  tags = var.tags
}

# CPU-based Auto Scaling Policy
resource "aws_appautoscaling_policy" "cpu" {
  for_each = {
    for k, v in var.services : k => v
    if lookup(v, "autoscaling_enabled", false)
  }

  name               = "${var.project_name}-${each.key}-cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.services[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.services[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.services[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = lookup(each.value, "target_cpu_utilization", var.target_cpu_utilization)
    scale_in_cooldown  = var.scale_in_cooldown
    scale_out_cooldown = var.scale_out_cooldown
  }
}

# Memory-based Auto Scaling Policy
resource "aws_appautoscaling_policy" "memory" {
  for_each = {
    for k, v in var.services : k => v
    if lookup(v, "autoscaling_enabled", false)
  }

  name               = "${var.project_name}-${each.key}-memory-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.services[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.services[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.services[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = lookup(each.value, "target_memory_utilization", var.target_memory_utilization)
    scale_in_cooldown  = var.scale_in_cooldown
    scale_out_cooldown = var.scale_out_cooldown
  }
}