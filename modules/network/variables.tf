variable "environment" {
  description = "Environment name (e.g., beta, prod)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zone_count" {
  description = "Number of availability zones to use"
  type        = number
  default     = 2
  validation {
    condition     = var.availability_zone_count >= 2
    error_message = "At least 2 availability zones are required for high availability."
  }
}

variable "enable_vpc_flow_logs" {
  description = "Enable VPC Flow Logs for network monitoring"
  type        = bool
  default     = true
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets (additional cost)"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
