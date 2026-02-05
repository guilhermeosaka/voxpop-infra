variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID to launch the bastion in"
  type        = string
}

variable "instance_type" {
  description = "Instance type for bastion"
  type        = string
  default     = "t4g.nano"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
