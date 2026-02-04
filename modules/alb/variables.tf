variable "environment" {
  description = "Environment name (e.g., beta, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where ALB will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for ALB (should be public subnets)"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs for ALB"
  type        = list(string)
}

variable "identity_port" {
  description = "Port for identity service"
  type        = number
  default     = 80
}

variable "core_port" {
  description = "Port for core service"
  type        = number
  default     = 80
}

variable "identity_health_check_path" {
  description = "Health check path for identity service"
  type        = string
  default     = "/health"
}

variable "core_health_check_path" {
  description = "Health check path for core service"
  type        = string
  default     = "/health"
}

variable "certificate_arn" {
  description = "ARN of ACM certificate for HTTPS (leave empty for HTTP only)"
  type        = string
  default     = ""
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection for ALB"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
