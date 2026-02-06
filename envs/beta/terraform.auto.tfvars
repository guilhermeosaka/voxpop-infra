# Auto-loaded by Terraform (safe to commit - no secrets!)
# This file provides default values for CI/CD

aws_region  = "us-east-1"
environment = "beta"

vpc_cidr                = "10.0.0.0/16"
availability_zone_count = 2
enable_vpc_flow_logs    = false
allowed_cidr_blocks     = ["0.0.0.0/0"]

github_org   = "guilhermeosaka"
github_repos = ["voxpop-services", "voxpop-infra", "voxpop-web"]

db_name     = "voxpop"
db_username = "voxpop_admin"



identity_container_image = "nginx:latest"
identity_container_port  = 8080
identity_cpu             = 256
identity_memory          = 512

core_container_image = "nginx:latest"
core_container_port  = 8080
core_cpu             = 256
core_memory          = 512

alb_certificate_arn = ""
