output "endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.this.endpoint
}

output "address" {
  description = "RDS instance address (hostname)"
  value       = aws_db_instance.this.address
}

output "port" {
  description = "RDS instance port"
  value       = aws_db_instance.this.port
}

output "database_name" {
  description = "Name of the database"
  value       = aws_db_instance.this.db_name
}

output "username" {
  description = "Master username"
  value       = aws_db_instance.this.username
  sensitive   = true
}

output "connection_string" {
  description = "PostgreSQL connection string (without password)"
  value       = "postgresql://${aws_db_instance.this.username}@${aws_db_instance.this.endpoint}/${aws_db_instance.this.db_name}"
  sensitive   = true
}

output "db_instance_id" {
  description = "RDS instance identifier"
  value       = aws_db_instance.this.id
}

output "db_instance_arn" {
  description = "RDS instance ARN"
  value       = aws_db_instance.this.arn
}
