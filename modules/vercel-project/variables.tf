variable "project_name" {
  description = "Name of the Vercel project"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository (org/repo)"
  type        = string
}

variable "core_api_url" {
  description = "Core API URL to inject as NEXT_PUBLIC_CORE_API_URL"
  type        = string
}

variable "identity_api_url" {
  description = "Identity API URL to inject as NEXT_PUBLIC_IDENTITY_API_URL"
  type        = string
}
