locals {
  base_environment = concat([
    {
      name  = "APP_ENV"
      value = var.app_env
    },
    {
      name  = "APP_DEBUG"
      value = var.app_debug
    },
    {
      name  = "DB_HOST"
      value = var.db_host
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
      name  = "DB_PASSWORD"
      value = var.db_password
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
      name  = "REDIS_HOST"
      value = var.redis_host
    },
    {
      name  = "REDIS_PORT"
      value = "6379"
    },
    {
      name  = "REDIS_SCHEME"
      value = "tls"
    },
    {
      name  = "REDIS_CACHE_DB"
      value = "1"
    },
    {
      name  = "REDIS_DB"
      value = "0"
    },
    {
      name  = "REDIS_CLIENT"
      value = "phpredis"
    },
    {
      name  = "REDIS_CLIENT"
      value = "phpredis"
    },
    {
      name  = "LOG_CHANNEL"
      value = "stderr"
    },
    {
      name  = "LOG_LEVEL"
      value = "info"
    },
    {
      name  = "LOG_STDERR_FORMATTER"
      value = "json"
    },
    {
      name  = "CACHE_STORE"
      value = var.cache_driver
    },
    {
      name  = "QUEUE_CONNECTION"
      value = var.queue_connection
    },
    {
      name  = "SESSION_DOMAIN"
      value = ".bdynamic.pt"
    },
    {
      name  = "HORIZON_PATH"
      value = "admin/horizon"
    }
  ], var.additional_environment_variables)

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

  services = var.services

}


# ECS Task Definition
resource "aws_ecs_task_definition" "app" {

  family                   = "${var.project_name}-app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = local.services["app"].cpu
  memory                   = local.services["app"].memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = "app"
      image     = var.app_image
      essential = true
      environment = concat([
        {
          name  = "CONTAINER_ROLE"
          valeu = "app"
        }
      ], local.base_environment)
      secrets = local.base_secrets

      helthcheck = length(var.php_health_check_command) > 0 ? {
        command     = var.php_health_check_command
        interval    = var.health_check_interval
        timeout     = var.health_check_timeout
        retries     = var.health_check_retries
        startPeriod = 30
      } : null

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-region"        = var.aws_region
          "awslogs-group"         = aws_cloudwatch_log_group.services["app"].name
          "awslogs-stream-prefix" = "ecs"
        }
      }

      workingDirectory = var.php_working_directory

    },
    {
      name      = "nginx"
      image     = var.nginx_image
      essential = true

      portMappings = [
        {
          containerPort = 80
          hostPort      = "tcp"
        }
      ]


      dependOn = [
        {
          containerName = "app"
          condition     = "HEALTHY"
        }
      ]

      # Healthcheck
      healthCheck = {
        command     = var.nginx_health_check_command
        interval    = var.health_check_interval
        timeout     = var.health_check_timeout
        retries     = var.health_check_retries
        startPeriod = 30
      }

      # Logging configuration
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

  ])

}

# ECS Service for app
resource "aws_ecs_service" "app" {
  name            = "${var.project_name}-app"
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = local.services["app"].desired_count
  launch_type     = "FARGATE"

  force_new_deployment = true

  network_configuration {
    security_groups  = var.security_group_ids
    subnets          = var.subnet_ids
    assign_public_ip = var.assign_public_ip
  }

  load_balancer {
    target_group_arn = var.app_target_group_arn
    container_name   = "nginx"
    container_port   = 80
  }

  health_check_grace_period_seconds = var.health_check_grace_period

  # Service Discovery
  dynamic "service_registries" {
    for_each = var.create_service_discovery ? [1] : []
    content {
      registry_arn = aws_service_discovery_service.services["app"].arn
    }
  }

  # Auto Scaling
  lifecycle {
    ignore_changes = [
      desired_count
    ]
  }

  # Platform Version
  platform_version = var.platform_version

  tags = var.tags

}


resource "aws_ssm_parameter" "app_key" {
  name  = "/${var.project_name}/${var.app_env}/app/key"
  type  = "SecureString"
  value = var.app_key

  tags = {
    Name = "${var.project_name}-app-key"
  }

}

# CloudWatch Log Groups for Services
resource "aws_cloudwatch_log_group" "services" {
  for_each = local.services

  name              = "/ecs/${var.project_name}-${each.key}"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Name = "${var.project_name}-${each.key}-logs"
  })
}

# Nginx log group (only created for app service)
resource "aws_cloudwatch_log_group" "nginx" {
  count = contains(keys(local.services), "app") ? 1 : 0

  name              = "/ecs/${var.project_name}/nginx"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Name = "${var.project_name}-nginx-logs"
  })
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
  for_each = local.services
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

# Auto Scaling Target
resource "aws_appautoscaling_target" "app" {
  count = contains(keys(local.services), "app") ? 1 : 0

  max_capacity       = local.services["app"].max_capacity
  min_capacity       = local.services["app"].min_capacity
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.app.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  tags = var.tags
}

# CPU-based Auto Scaling Policy
resource "aws_appautoscaling_policy" "app_cpu" {
  count = contains(keys(local.services), "app") ? 1 : 0

  name               = "${var.project_name}-app-cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.app[0].resource_id
  scalable_dimension = aws_appautoscaling_target.app[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.app[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = local.services["app"].target_cpu_utilization
    scale_in_cooldown  = var.scale_in_cooldown
    scale_out_cooldown = var.scale_out_cooldown
  }
}

# Memory-based Auto Scaling Policy
resource "aws_appautoscaling_policy" "app_memory" {
  count = contains(keys(local.services), "app") ? 1 : 0

  name               = "${var.project_name}-app-memory-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.app[0].resource_id
  scalable_dimension = aws_appautoscaling_target.app[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.app[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = local.services["app"].target_memory_utilization
    scale_in_cooldown  = var.scale_in_cooldown
    scale_out_cooldown = var.scale_out_cooldown
  }
}
