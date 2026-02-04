output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name (use this for HTTPS access)"
  value       = aws_cloudfront_distribution.this.domain_name
}

output "cloudfront_url" {
  description = "Full HTTPS URL for CloudFront distribution"
  value       = "https://${aws_cloudfront_distribution.this.domain_name}"
}

output "cloudfront_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.this.id
}

output "cloudfront_arn" {
  description = "CloudFront distribution ARN"
  value       = aws_cloudfront_distribution.this.arn
}

output "cloudfront_status" {
  description = "CloudFront distribution status"
  value       = aws_cloudfront_distribution.this.status
}

output "cloudfront_hosted_zone_id" {
  description = "CloudFront hosted zone ID (for Route 53)"
  value       = aws_cloudfront_distribution.this.hosted_zone_id
}
