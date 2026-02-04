# CloudFront Distribution Module
# Provides free HTTPS without requiring a custom domain

# CloudFront Origin Access Identity (for future S3 integration)
resource "aws_cloudfront_origin_access_identity" "this" {
  comment = "voxpop-${var.environment}-oai"
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "this" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "voxpop-${var.environment}-distribution"
  price_class         = var.price_class
  http_version        = "http2and3"
  wait_for_deployment = var.wait_for_deployment

  # ALB Origin
  origin {
    domain_name = var.alb_dns_name
    origin_id   = "alb"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only" # ALB is HTTP only
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    custom_header {
      name  = "X-Custom-Header"
      value = var.custom_header_value
    }
  }

  # Default Cache Behavior
  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "alb"

    forwarded_values {
      query_string = true
      headers      = ["Host", "Authorization", "Accept", "Content-Type"]

      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = "redirect-to-https" # Force HTTPS
    min_ttl                = 0
    default_ttl            = var.default_ttl
    max_ttl                = var.max_ttl
    compress               = true
  }

  # Cache behavior for /identity path
  ordered_cache_behavior {
    path_pattern     = "/identity/*"
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "alb"

    forwarded_values {
      query_string = true
      headers      = ["Host", "Authorization", "Accept", "Content-Type"]

      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0 # Don't cache API responses
    max_ttl                = 0
    compress               = true
  }

  # Cache behavior for /core path
  ordered_cache_behavior {
    path_pattern     = "/core/*"
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "alb"

    forwarded_values {
      query_string = true
      headers      = ["Host", "Authorization", "Accept", "Content-Type"]

      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0 # Don't cache API responses
    max_ttl                = 0
    compress               = true
  }

  # Viewer Certificate (CloudFront default SSL)
  viewer_certificate {
    cloudfront_default_certificate = true # Free HTTPS!
  }

  # Restrictions
  restrictions {
    geo_restriction {
      restriction_type = var.geo_restriction_type
      locations        = var.geo_restriction_locations
    }
  }

  tags = merge(
    var.tags,
    {
      Name        = "voxpop-${var.environment}-cloudfront"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  )
}
