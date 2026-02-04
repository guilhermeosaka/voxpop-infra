variable "environment" {
  description = "Environment name (e.g., beta, prod)"
  type        = string
}

variable "github_org" {
  description = "GitHub organization or username"
  type        = string
  default     = "guilhermeosaka"
}

variable "github_repos" {
  description = "List of GitHub repository names allowed to assume the role"
  type        = list(string)
  default     = ["voxpop", "voxpop-infra"]
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
