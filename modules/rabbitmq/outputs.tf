output "service_name" {
  description = "RabbitMQ ECS service name"
  value       = aws_ecs_service.rabbitmq.name
}

output "task_definition_arn" {
  description = "RabbitMQ task definition ARN"
  value       = aws_ecs_task_definition.rabbitmq.arn
}

output "internal_endpoint" {
  description = "Internal endpoint for RabbitMQ (service discovery DNS)"
  value       = var.enable_service_discovery ? "rabbitmq.${var.environment}.voxpop.local" : "Use task private IP"
}

output "amqp_port" {
  description = "AMQP port"
  value       = 5672
}

output "management_port" {
  description = "Management UI port"
  value       = 15672
}

output "connection_string" {
  description = "RabbitMQ connection string (AMQP URL)"
  value       = var.enable_service_discovery ? "amqp://${var.rabbitmq_username}:${var.rabbitmq_password}@rabbitmq.${var.environment}.voxpop.local:5672" : "amqp://${var.rabbitmq_username}:${var.rabbitmq_password}@<task-ip>:5672"
  sensitive   = true
}

output "management_url" {
  description = "RabbitMQ management UI URL"
  value       = var.enable_service_discovery ? "http://rabbitmq.${var.environment}.voxpop.local:15672" : "http://<task-ip>:15672"
}
