variable "environment" {
  description = "Environment name (e.g., beta, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where RDS will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for RDS (should be private subnets)"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs for RDS"
  type        = list(string)
}

variable "db_name" {
  description = "Name of the initial database to create (optional - set to null to skip initial DB creation)"
  type        = string
  default     = null
}

variable "db_username" {
  description = "Master username for the database"
  type        = string
  default     = "voxpop_admin"
}

variable "db_password" {
  description = "Master password for the database"
  type        = string
  sensitive   = true
}

variable "engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "16.3"
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t4g.micro" # ARM-based, cost-optimized
}

variable "allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20
}

variable "backup_retention_period" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment for high availability"
  type        = bool
  default     = false # Disabled for beta to save costs
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot when destroying (set to false for production)"
  type        = bool
  default     = true # Enabled for beta to allow easy cleanup
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = false # Disabled for beta to allow easy cleanup
}

variable "monitoring_interval" {
  description = "Enhanced monitoring interval in seconds (0 to disable, 1, 5, 10, 15, 30, 60)"
  type        = number
  default     = 0 # Disabled for beta to save costs
}

variable "enable_performance_insights" {
  description = "Enable Performance Insights"
  type        = bool
  default     = false # Disabled for beta to save costs
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
