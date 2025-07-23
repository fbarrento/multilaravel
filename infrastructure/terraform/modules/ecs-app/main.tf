# Service Discovery Namespace
resource "aws_service_discovery_private_dns_namespace" "main" {
  count       = var.create_service_discovery ? 1 : 0
  name        = "${var.project_name}.local"
  description = "Private DNS namespace for ${var.project_name}"
  vpc         = var.vpc_id

  tags = var.tags
}

# Service Discovery Service
resource "aws_service_discovery_service" "app" {
  count = var.create_service_discovery ? 1 : 0
  name  = "app"

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

# ECS Task Definition
resource "aws_ecs_task_definition" "app" {

  family                   = "${var.project_name}-app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.fargate_cpu
  memory                   = var.fargate_memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = "php",
      image     = var.app_image
      essential = true

      environment = concat([
        {
          name  = "CONTAINER_ROLE"
          value = "app"
        },
        {
          name  = "APP_ENV"
          value = var.app_env
        },
        {
          name  = "APP_DEBUG"
          value = tostring(var.app_debug)
        },
        {
          name  = "APP_KEY"
          value = var.app_key
        },
        {
          name  = "DB_HOST"
          value = var.db_host
        },
        {
          name  = "DB_PORT"
          value = "3306"
        },
        {
          name  = "DB_CONNECTION"
          value = "mysql"
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
          name  = "LOG_CHANNEL"
          value = "stderr"
        }
      ], var.additional_environment_variables)

      secrets = [
        {
          name      = "DB_PASSWORD"
          valueFrom = var.db_password_parameter_arn
        },
        {
          name      = "REDIS_PASSWORD"
          valueFrom = var.redis_password_parameter_arn
        }
      ]


      healthCheck = length(var.php_health_check_command) > 0 ? {
        command     = var.php_health_check_command
        interval    = var.health_check_interval
        timeout     = var.health_check_timeout
        retries     = var.health_check_retries
        startPeriod = 30
      } : null

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = var.app_log_group_name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      workingDirectory = var.php_working_directory
    },
    {
      name      = "nginx"
      image     = var.nginx_image
      essential = true

      # Port mappings
      portMappings = [
        {
          containerPort = 80
          protocol      = "tcp"
        }
      ]

      dependsOn = [
        {
          containerName = "php"
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
          "awslogs-group"         = var.nginx_log_group_name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      # Working directory
      workingDirectory = var.nginx_working_directory


    }
  ])

  tags = var.tags

}

# ECS Service for the app
resource "aws_ecs_service" "app" {
  name            = "${var.project_name}-app"
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.app_count
  launch_type     = "FARGATE"

  force_new_deployment = true

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = var.security_group_ids
    assign_public_ip = var.assign_pubic_ip
  }

  load_balancer {
    container_name   = "nginx"
    container_port   = 80
    target_group_arn = var.target_group_arn
  }

  health_check_grace_period_seconds = var.health_check_grace_period

  # Service Discovery
  dynamic "service_registries" {
    for_each = var.create_service_discovery ? [1] : []
    content {
      registry_arn = aws_service_discovery_service.app[0].arn
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

resource "aws_appautoscaling_target" "app" {
  count              = var.autoscaling_enabled ? 1 : 0
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.app.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  tags = var.tags
}

# CPU-based Auto Scaling Policy
resource "aws_appautoscaling_policy" "app_cpu" {
  count              = var.autoscaling_enabled ? 1 : 0
  name               = "${var.project_name}-cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.app[0].resource_id
  scalable_dimension = aws_appautoscaling_target.app[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.app[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = var.target_cpu_utilization
    scale_in_cooldown  = var.scale_in_cooldown
    scale_out_cooldown = var.scale_out_cooldown
  }
}

# Memory-based Auto Scaling Policy
resource "aws_appautoscaling_policy" "app_memory" {
  count              = var.autoscaling_enabled ? 1 : 0
  name               = "${var.project_name}-memory-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.app[0].resource_id
  scalable_dimension = aws_appautoscaling_target.app[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.app[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = var.target_memory_utilization
    scale_in_cooldown  = var.scale_in_cooldown
    scale_out_cooldown = var.scale_out_cooldown
  }
}