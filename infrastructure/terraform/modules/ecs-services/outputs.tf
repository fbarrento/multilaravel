output "service_names" {
  description = "Names of the created ECS services"
  value       = [
    aws_ecs_service.app.name
  ]
}

output "service_discovery_namespace" {
  description = "Service discovery namespace"
  value       = var.create_service_discovery ? aws_service_discovery_private_dns_namespace.main[0].name : null
}

output "service_discovery_services" {
  description = "Service discovery service ARNs"
  value = var.create_service_discovery ? {
    for k, v in aws_service_discovery_service.services : k => v.arn
  } : {}
}

output "task_definition_arns" {
  description = "ARNs of the ECS task definitions"
  value = [
    { aws_ecs_task_definition.app.name : aws_ecs_task_definition.app.arn }
  ]
}

output "log_group_names" {
  description = "Names of the CloudWatch log groups"
  value = {
    for k, v in aws_cloudwatch_log_group.services : k => v.name
  }
}

