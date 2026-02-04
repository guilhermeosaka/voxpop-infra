variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "beta"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zone_count" {
  description = "Number of availability zones"
  type        = number
  default     = 2
}

variable "enable_vpc_flow_logs" {
  description = "Enable VPC Flow Logs (can disable for cost savings)"
  type        = bool
  default     = false # Disabled for beta to save costs
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access ECS tasks"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Restrict this to your IP for better security
}

variable "github_org" {
  description = "GitHub organization or username"
  type        = string
  default     = "guilhermeosaka"
}

variable "github_repos" {
  description = "List of GitHub repositories allowed to use OIDC role"
  type        = list(string)
  default     = ["voxpop", "voxpop-infra"]
}

# RDS Variables
variable "db_name" {
  description = "Database name"
  type        = string
  default     = "voxpop"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "voxpop_admin"
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

# RabbitMQ Variables
variable "enable_rabbitmq" {
  description = "Enable RabbitMQ deployment"
  type        = bool
  default     = false
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
  default     = ""
}

# Identity Service Variables
variable "identity_container_image" {
  description = "Docker image for voxpop-identity service"
  type        = string
  default     = "nginx:latest" # Replace with your actual image
}

variable "identity_container_port" {
  description = "Port for voxpop-identity service"
  type        = number
  default     = 8080
}

variable "identity_cpu" {
  description = "CPU units for voxpop-identity service"
  type        = number
  default     = 256
}

variable "identity_memory" {
  description = "Memory for voxpop-identity service in MB"
  type        = number
  default     = 512
}

# Core Service Variables
variable "core_container_image" {
  description = "Docker image for voxpop-core service"
  type        = string
  default     = "nginx:latest" # Replace with your actual image
}

variable "core_container_port" {
  description = "Port for voxpop-core service"
  type        = number
  default     = 8080
}

variable "core_cpu" {
  description = "CPU units for voxpop-core service"
  type        = number
  default     = 256
}

variable "core_memory" {
  description = "Memory for voxpop-core service in MB"
  type        = number
  default     = 512
}

# ALB Variables
variable "alb_certificate_arn" {
  description = "ARN of ACM certificate for HTTPS (leave empty for HTTP only)"
  type        = string
  default     = ""
}
