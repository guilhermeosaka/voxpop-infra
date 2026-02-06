# Network Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.network.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = module.network.private_subnet_ids
}

# RDS Outputs
output "database_endpoint" {
  description = "RDS database endpoint"
  value       = module.rds.endpoint
}

output "database_name" {
  description = "Database name"
  value       = module.rds.database_name
}



# ALB Outputs
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.alb.alb_dns_name
}

output "alb_url" {
  description = "URL to access the ALB"
  value       = module.alb.alb_url
}

output "api_endpoints" {
  description = "API endpoints for services"
  value = {
    identity = "${module.alb.alb_url}/identity"
    core     = "${module.alb.alb_url}/core"
  }
}

# CloudFront Outputs (HTTPS URLs)
output "cloudfront_url" {
  description = "CloudFront HTTPS URL (use this for secure access)"
  value       = module.cloudfront.cloudfront_url
}

output "cloudfront_domain" {
  description = "CloudFront domain name"
  value       = module.cloudfront.cloudfront_domain_name
}

output "https_api_endpoints" {
  description = "HTTPS API endpoints via CloudFront"
  value = {
    identity = "${module.cloudfront.cloudfront_url}/identity"
    core     = "${module.cloudfront.cloudfront_url}/core"
  }
}

# ECS Outputs
output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs_cluster.cluster_name
}

output "identity_service_name" {
  description = "Name of the identity service"
  value       = module.identity_service.service_name
}

output "core_service_name" {
  description = "Name of the core service"
  value       = module.core_service.service_name
}

# IAM Outputs
output "github_actions_role_arn" {
  description = "ARN of the GitHub Actions role for CI/CD"
  value       = module.iam.github_actions_role_arn
}

# Instructions
output "how_to_get_task_ips" {
  description = "Instructions to get the public IPs of your ECS tasks"
  value       = <<-EOT
    Identity Service: aws ecs list-tasks --cluster ${module.ecs_cluster.cluster_name} --service-name ${module.identity_service.service_name}
    Core Service: aws ecs list-tasks --cluster ${module.ecs_cluster.cluster_name} --service-name ${module.core_service.service_name}
    Then: aws ecs describe-tasks --cluster ${module.ecs_cluster.cluster_name} --tasks <task-arn>
  EOT
}
output "bastion_instance_id" {
  description = "ID of the Bastion Host"
  value       = module.bastion.instance_id
}

output "ssm_connect_command" {
  description = "Command to start SSM Port Forwarding session"
  value       = "aws ssm start-session --target ${module.bastion.instance_id} --document-name AWS-StartPortForwardingSessionToRemoteHost --parameters '{\"host\":[\"${module.rds.address}\"],\"portNumber\":[\"5432\"], \"localPortNumber\":[\"4321\"]}'"
}
