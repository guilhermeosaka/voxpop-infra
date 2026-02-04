output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.this.arn
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.this.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = aws_lb.this.zone_id
}

output "identity_target_group_arn" {
  description = "ARN of the identity service target group"
  value       = aws_lb_target_group.identity.arn
}

output "core_target_group_arn" {
  description = "ARN of the core service target group"
  value       = aws_lb_target_group.core.arn
}

output "http_listener_arn" {
  description = "ARN of the HTTP listener"
  value       = aws_lb_listener.http.arn
}

output "https_listener_arn" {
  description = "ARN of the HTTPS listener (if enabled)"
  value       = var.certificate_arn != "" ? aws_lb_listener.https[0].arn : null
}

output "alb_url" {
  description = "URL to access the ALB"
  value       = var.certificate_arn != "" ? "https://${aws_lb.this.dns_name}" : "http://${aws_lb.this.dns_name}"
}
