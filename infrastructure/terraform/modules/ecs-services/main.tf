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
      value = var.app_env
    },
    {
      name  = "APP_DEBUG"
      value = tostring(var.app_debug)
    },
    {
      name  = "LOG_LEVEL"
      value = var.log_level
    },
    {
      name  = "DB_HOST"
      value = var.db_host
    },
    {
      name  = "DB_PORT"
      value = var.db_port
    },
    {
      name  = "DB_CONNECTION"
      value = var.db_connection
    },
    {
      name  = "DB_DATABASE"
      value = var.db_name
    },
    {
      name  = "DB_USERNAME"
      value = var.db_username
    },
    {
      name  = "REDIS_HOST"
      value = var.redis_host
    },
    {
      name  = "REDIS_PORT"
      value = var.redis_port
    },
    {
      name  = "REDIS_SCHEME"
      value = var.redis_scheme
    },
    {
      name  = "REDIS_CACHE_DB"
      value = var.redis_cache_db
    },
    {
      name  = "REDIS_DB"
      value = var.redis_db
    },
    {
      name  = "REDIS_CLIENT"
      value = var.redis_client
    },
    {
      name  = "LOG_CHANNEL"
      value = var.log_channel
    },
    {
      name  = "LOG_STDERR_FORMATTER"
      value = var.log_stderr_formatter
    },
    {
      name  = "CACHE_STORE"
      value = var.cache_store
    },
    {
      name  = "QUEUE_CONNECTION"
      value = var.queue_connection
    },
    {
      name  = "SESSION_DOMAIN"
      value = var.session_domain
    },
    {
      name  = "BROADCAST_CONNECTION"
      value = var.broadcast_connection
    },
    {
      name  = "REVERB_HOST"
      value = var.reverb_host
    },
    {
      name  = "REVERB_PORT"
      value = tostring(var.reverb_port)
    },
    {
      name  = "REVERB_SCHEME"
      value = var.reverb_scheme
    }
  ]



  base_secrets = [
    {
      name      = "APP_KEY"
      valueFrom = aws_ssm_parameter.app_key.arn
    },
    {
      name      = "DB_PASSWORD"
      valueFrom = var.db_password_parameter_arn
    },
    {
      name      = "REDIS_PASSWORD"
      valueFrom = var.redis_password_parameter_arn
    }
  ]
}



# ECS Task Definition
resource "aws_ecs_task_definition" "services" {
  for_each = var.services

  family                   = "${var.project_name}-app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.fargate_cpu
  memory                   = var.fargate_memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    merge(
      {
        name      = "app",
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
          lookup(each.value, "additional_environment", [])
        )

        secrets = concat(
          local.base_secrets,
          lookup(each.value, "additional_secrets", [])
        )

        logConfiguration = {
          logDriver = "awslogs"
          options = {
            awslogs-group         = aws_cloudwatch_log_group.services[each.key].name
            awslogs-region        = var.aws_region
            awslogs-stream-prefix = "ecs"
          }
        }

        workingDirectory = each.value["working_directory"]

      },

      # Service-specific Configuration
      each.key == "app" ? {
        portMappings = [
          {
            containerPort = 9000
            protocol      = "tcp"
          }
        ]

        healthCheck = {
          command     = var.php_health_check_command
          interval    = var.health_check_interval
          timeout     = var.health_check_timeout
          retries     = var.health_check_retries
          startPeriod = 30
        }

      } : {},

      each.key == "reverb" ? {
        portMappings = [
          {
            containerPort = var.reverb_port
            protocol      = "tcp"
          }
        ]
        healthCheck = {
          command     = ["CMD-SHELL", "curl -f http://localhost:${var.reverb_port}/health || exit 1"]
          interval    = var.health_check_interval
          timeout     = var.health_check_timeout
          retries     = var.health_check_retries
          startPeriod = 60
        }
      } : {},
      # For worker, scheduler, and horizon - no port mappings needed
      contains(["worker", "scheduler", "horizon"], each.key) ? {
        healthCheck = {
          command     = ["CMD-SHELL", "ps aux | grep -E '(queue:work|schedule:run|horizon)' | grep -v grep || exit 1"]
          interval    = var.health_check_interval
          timeout     = var.health_check_timeout
          retries     = var.health_check_retries
          startPeriod = 60
        }
      } : {}
    ),

    # Nginx container only for app service
    each.key == "app" ? {
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
    } : {}
  ])

  tags = var.tags

}

# CloudWatch Log Group for services
resource "aws_cloudwatch_log_group" "services" {
  for_each = var.services

  name              = "/${var.project_name}/${each.key}"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Name = "${var.project_name}-${each.key}-logs"
  })

}

# Nginx log group (only created for app service)
resource "aws_cloudwatch_log_group" "nginx" {
  count = contains(keys(var.services), "app") ? 1 : 0

  name              = "/aws/ecs/${var.project_name}/nginx"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Name = "${var.project_name}-nginx-logs"
  })
}


# ECS Service for the app
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
    assign_public_ip = var.assign_pubic_ip
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
      target_group_arn = var.app_target_group_arn
    }
  }

  health_check_grace_period_seconds = var.health_check_grace_period

  # Service Discovery
  dynamic "service_registries" {
    for_each = var.create_service_discovery ? [1] : []
    content {
      registry_arn = aws_service_discovery_service.services[0].arn
    }
  }

  # Auto Scaling
  lifecycle {
    ignore_changes = [desired_count]
  }

  # Platform Version
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
  name               = "${var.project_name}-cpu-autoscaling"
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
resource "aws_appautoscaling_policy" "app_memory" {
  for_each = {
    for k, v in var.services : k => v
    if lookup(v, "autoscaling_enabled", false)
  }
  name               = "${var.project_name}-memory-autoscaling"
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