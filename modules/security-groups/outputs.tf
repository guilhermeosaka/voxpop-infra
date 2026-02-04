output "ecs_tasks_sg_id" {
  description = "ID of the ECS tasks security group"
  value       = aws_security_group.ecs_tasks.id
}

output "alb_sg_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "database_sg_id" {
  description = "ID of the database security group"
  value       = aws_security_group.database.id
}

output "rabbitmq_sg_id" {
  description = "ID of the RabbitMQ security group"
  value       = var.enable_rabbitmq ? aws_security_group.rabbitmq[0].id : null
}
