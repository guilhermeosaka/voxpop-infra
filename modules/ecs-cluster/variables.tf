variable "environment" {
  description = "Environment name (e.g., beta, prod)"
  type        = string
}

variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
  default     = "voxpop"
}

variable "enable_container_insights" {
  description = "Enable CloudWatch Container Insights for the cluster"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
