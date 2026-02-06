variable "project_name" {
  description = "Name of the Vercel project"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository (org/repo)"
  type        = string
}

variable "api_url" {
  description = "API URL to inject as NEXT_PUBLIC_API_URL"
  type        = string
}
