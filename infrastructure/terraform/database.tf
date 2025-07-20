# RDS Subnet Group
resource "aws_db_subnet_group" "main" {
    name       = "${var.project_name}-rds-subnet-group"
    subnet_ids = aws_subnet.private[*].id

    tags = {
      Name = "${var.project_name}-rds-subnet-group"
    }
}

# RDS Parameter Group
resource "aws_db_parameter_group" "main" {
  name   = "${var.project_name}-db-params"
  family = "mysql8.0"

  parameter {
    name  = "innodb_buffer_pool_size"
    value = "{DBInstanceClassMemory*3/4}"
  }

  parameter {
    name = "max_connections"
    value = "200"
  }

  parameter {
    name = "slow_query_log"
    value = "1"
  }

  parameter {
    name = "long_query_time"
    value = "2"
  }

  tags = {
    Name = "${var.project_name}-db-parameter-group"
  }

}

# RDS Instance
resource "aws_db_instance" "main" {
  identifier = "${var.project_name}-${var.environment}-db"

  # Engine Settings
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = var.db_instance_class

  # Database Settings
  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_allocated_storage * 2
  storage_type          = "gp3"
  storage_encrypted = true

  # Database configuration
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  # Network Settings
  db_subnet_group_name = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible  = false
  port = "3306"

  # Backup Settings
  backup_retention_period = var.db_backup_retention_period
  backup_window           = var.backup_window
  maintenance_window      = var.maintenance_window
  delete_automated_backups = !var.enable_automated_backup

  # Monitoring and Performance Settings
  performance_insights_enabled = contains(["db.t3.micro", "db.t3.small"], var.db_instance_class) ? false : true
  monitoring_interval          = 60
  monitoring_role_arn = aws_iam_role.rds_enhanced_monitoring_role.arn

  # High Availability Settings
  multi_az = var.db_multi_az

  # Parameter Group
  parameter_group_name = aws_db_parameter_group.main.name

  # Deletion Protection
  deletion_protection = var.enable_deletion_protection
  skip_final_snapshot = !var.enable_deletion_protection

  # Apply changes immediately in non-production environments
  apply_immediately = var.environment != "prod"

  tags = {
    Name = "${var.project_name}-db"
  }

}

# RDS Enhanced Monitoring Role
resource "aws_iam_role" "rds_enhanced_monitoring_role" {
  name = "${var.project_name}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-rds-monitoring-role"
  }
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  role       = aws_iam_role.rds_enhanced_monitoring_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# Elasticache Subnet Group
resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.project_name}-cache-subnet"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "${var.project_name}-cache-subnet"
  }
}

# Elasticache Parameter Group
resource "aws_elasticache_parameter_group" "main" {
  name   = "${var.project_name}-cache-params"
  family = "redis7"

  parameter {
    name = "maxmemory-policy"
    value = "allkeys-lru"
  }

  parameter {
    name = "timeout"
    value = "300"
  }

  tags = {
    Name = "${var.project_name}-cache-params"
  }

}

# ElasticCache Redis Cluster
resource "aws_elasticache_replication_group" "main" {
  replication_group_id = "${var.project_name}-redis"
  description = "Redis Cluster for ${var.project_name}"

  # Node configuration
  node_type = var.redis_node_type
  port = var.redis_port

  # Cluster configuration
  num_cache_clusters = var.redis_num_cache_nodes

  # Parameter Group
  parameter_group_name = aws_elasticache_parameter_group.main.name

  # Network Settings
  subnet_group_name = aws_elasticache_subnet_group.main.name
  security_group_ids = [aws_security_group.redis.id]

  # Security
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token = random_password.auth_token.result

  # Backup Settings
  snapshot_retention_limit = 5
  snapshot_window = "07:00-09:00"

  # Maintenance Settings
  maintenance_window = "sun:04:00-sun:05:00"

  # Automatic failover
  automatic_failover_enabled = var.redis_num_cache_nodes > 1

  # Apply changes immediately in non-production environments
  apply_immediately = var.environment != "prod"

  tags = {
    Name = "${var.project_name}-redis"
  }

}

# Redis Auth Token
resource "random_password" "auth_token" {
  length = 32
  special = false
}

# Store Redis Auth Token in AWS System Manager Parameter Store
resource "aws_ssm_parameter" "redis_auth_token" {
  name  = "/${var.project_name}/${var.environment}/redis/auth-token"
  type  = "SecureString"
  value = random_password.auth_token.result

  tags = {
    Name = "${var.project_name}-redis-auth-token"
  }

}

# Store database credentials in AWS System Manager Parameter Store
resource "aws_ssm_parameter" "db_credentials" {
  name  = "/${var.project_name}/${var.environment}/db/password"
  type  = "SecureString"
  value = var.db_password

  tags = {
    Name = "${var.project_name}-db-password"
  }

}

# CloudWatch Alarms for RDS
resource "aws_cloudwatch_metric_alarm" "database_cpu" {
  alarm_name          = "${var.project_name}-database-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"
  alarm_description = "This metric monitors RDS CPU utilization"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }

  tags = {
    Name = "${var.project_name}-database-cpu-alarm"
  }

}

resource "aws_cloudwatch_metric_alarm" "database_connections" {
  alarm_name          = "${var.project_name}-database-connections"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = "120"
  statistic           = "Average"
  threshold           = "150"
  alarm_description = "This metric monitors RDS database connections"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }

  tags = {
    Name = "${var.project_name}-database-connections-alarm"
  }
}

# CloudWatch Alarms for Elasticache
resource "aws_cloudwatch_metric_alarm" "redis_cpu" {
  alarm_name          = "${var.project_name}-redis-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ElastiCache"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors Redis CPU utilization"

  dimensions = {
    CacheClusterId = aws_elasticache_replication_group.main.id
  }

}

resource "aws_cloudwatch_metric_alarm" "redis_memory" {
  alarm_name          = "${var.project_name}-redis-memory-usage"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DatabaseMemoryUsagePercentage"
  namespace           = "AWS/ElastiCache"
  period              = "120"
  statistic           = "Average"
  threshold           = "90"
  alarm_description   = "This metric monitors Redis memory utilization"

  dimensions = {
    CacheClusterId = "${aws_elasticache_replication_group.main.replication_group_id}-001"
  }

  tags = {
    Name = "${var.project_name}-redis-memory-alarm"
  }

}