variable "environment" {
  description = "Environment name (e.g., beta, prod)"
  type        = string
}

variable "github_org" {
  description = "GitHub organization or username"
  type        = string
  default     = "guilhermeosaka"
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
  default     = "voxpop"
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
