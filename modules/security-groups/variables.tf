variable "environment" {
  description = "Environment name (e.g., beta, prod)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC"
  type        = string
}

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to access ECS tasks (for beta, use specific IPs)"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Default to open, should be restricted in beta
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "enable_rabbitmq" {
  description = "Enable RabbitMQ security group"
  type        = bool
  default     = false
}
