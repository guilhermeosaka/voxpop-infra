# Application Load Balancer Module

# Application Load Balancer
resource "aws_lb" "this" {
  name               = "voxpop-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = var.security_group_ids
  subnets            = var.subnet_ids

  enable_deletion_protection       = var.enable_deletion_protection
  enable_http2                     = true
  enable_cross_zone_load_balancing = true

  tags = merge(
    var.tags,
    {
      Name        = "voxpop-${var.environment}-alb"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  )
}

# Target Group for Identity Service
resource "aws_lb_target_group" "identity" {
  name        = "voxpop-${var.environment}-identity-tg"
  port        = var.identity_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = var.identity_health_check_path
    matcher             = "200"
  }

  deregistration_delay = 30

  tags = merge(
    var.tags,
    {
      Name        = "voxpop-${var.environment}-identity-tg"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  )
}

# Target Group for Core Service
resource "aws_lb_target_group" "core" {
  name        = "voxpop-${var.environment}-core-tg"
  port        = var.core_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = var.core_health_check_path
    matcher             = "200"
  }

  deregistration_delay = 30

  tags = merge(
    var.tags,
    {
      Name        = "voxpop-${var.environment}-core-tg"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  )
}

# HTTP Listener (redirects to HTTPS if certificate is provided)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = var.certificate_arn != "" ? "redirect" : "fixed-response"

    dynamic "redirect" {
      for_each = var.certificate_arn != "" ? [1] : []
      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }

    dynamic "fixed_response" {
      for_each = var.certificate_arn == "" ? [1] : []
      content {
        content_type = "text/plain"
        message_body = "Service Unavailable"
        status_code  = "503"
      }
    }
  }

  tags = merge(
    var.tags,
    {
      Name        = "voxpop-${var.environment}-http-listener"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  )
}

# HTTPS Listener (optional, requires certificate)
resource "aws_lb_listener" "https" {
  count             = var.certificate_arn != "" ? 1 : 0
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = "404"
    }
  }

  tags = merge(
    var.tags,
    {
      Name        = "voxpop-${var.environment}-https-listener"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  )
}

# Listener Rule for Identity Service (HTTP)
resource "aws_lb_listener_rule" "identity_http" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.identity.arn
  }

  condition {
    path_pattern {
      values = ["/identity/*", "/identity"]
    }
  }

  tags = merge(
    var.tags,
    {
      Name        = "voxpop-${var.environment}-identity-http-rule"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  )
}

# Listener Rule for Core Service (HTTP)
resource "aws_lb_listener_rule" "core_http" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 200

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.core.arn
  }

  condition {
    path_pattern {
      values = ["/core/*", "/core", "/*"]
    }
  }

  tags = merge(
    var.tags,
    {
      Name        = "voxpop-${var.environment}-core-http-rule"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  )
}

# Listener Rule for Identity Service (HTTPS)
resource "aws_lb_listener_rule" "identity_https" {
  count        = var.certificate_arn != "" ? 1 : 0
  listener_arn = aws_lb_listener.https[0].arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.identity.arn
  }

  condition {
    path_pattern {
      values = ["/identity/*", "/identity"]
    }
  }

  tags = merge(
    var.tags,
    {
      Name        = "voxpop-${var.environment}-identity-https-rule"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  )
}

# Listener Rule for Core Service (HTTPS)
resource "aws_lb_listener_rule" "core_https" {
  count        = var.certificate_arn != "" ? 1 : 0
  listener_arn = aws_lb_listener.https[0].arn
  priority     = 200

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.core.arn
  }

  condition {
    path_pattern {
      values = ["/core/*", "/core", "/*"]
    }
  }

  tags = merge(
    var.tags,
    {
      Name        = "voxpop-${var.environment}-core-https-rule"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  )
}
