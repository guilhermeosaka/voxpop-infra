terraform {
  required_providers {
    vercel = {
      source = "vercel/vercel"
    }
  }
}

resource "vercel_project" "this" {
  name      = var.project_name
  framework = "nextjs"

  git_repository = {
    type = "github"
    repo = var.github_repo
  }
}

resource "vercel_project_environment_variable" "core_api_url" {
  project_id = vercel_project.this.id
  key        = "NEXT_PUBLIC_CORE_API_URL"
  value      = var.core_api_url
  target     = ["production", "preview", "development"]
}

resource "vercel_project_environment_variable" "identity_api_url" {
  project_id = vercel_project.this.id
  key        = "NEXT_PUBLIC_IDENTITY_API_URL"
  value      = var.identity_api_url
  target     = ["production", "preview", "development"]
}
