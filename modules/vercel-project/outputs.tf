output "project_id" {
  value = vercel_project.this.id
}

output "project_url" {
  value = "https://${vercel_project.this.name}.vercel.app"
  # Note: This is an approximation/default. Real custom domains are handled separately.
}
