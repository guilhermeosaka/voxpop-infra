variable "environment" {
  description = "Environment name (e.g., beta, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where RabbitMQ will be deployed"
  type        = string
}

variable "cluster_id" {
  description = "ECS cluster ID"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for RabbitMQ (should be private subnets)"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs for RabbitMQ"
  type        = list(string)
}

variable "task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  type        = string
}

variable "task_role_arn" {
  description = "ARN of the ECS task role"
  type        = string
}

variable "rabbitmq_version" {
  description = "RabbitMQ version"
  type        = string
  default     = "3.13"
}

variable "rabbitmq_username" {
  description = "RabbitMQ admin username"
  type        = string
  default     = "admin"
}

variable "rabbitmq_password" {
  description = "RabbitMQ admin password"
  type        = string
  sensitive   = true
}

variable "cpu" {
  description = "CPU units for RabbitMQ task"
  type        = number
  default     = 512
}

variable "memory" {
  description = "Memory for RabbitMQ task in MB"
  type        = number
  default     = 1024
}

variable "enable_service_discovery" {
  description = "Enable AWS Cloud Map service discovery for internal DNS"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
