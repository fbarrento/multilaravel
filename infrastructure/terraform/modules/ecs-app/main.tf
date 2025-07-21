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