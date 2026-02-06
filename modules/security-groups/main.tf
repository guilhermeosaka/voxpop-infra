# Security Group for ECS Tasks
resource "aws_security_group" "ecs_tasks" {
  name        = "voxpop-${var.environment}-ecs-tasks-sg"
  description = "Security group for ECS tasks"
  vpc_id      = var.vpc_id

  # Allow HTTP from ALB
  ingress {
    description     = "HTTP from ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # Allow all outbound traffic
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name        = "voxpop-${var.environment}-ecs-tasks-sg"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  )
}

# Security Group for Application Load Balancer
resource "aws_security_group" "alb" {
  name        = "voxpop-${var.environment}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = var.vpc_id

  # Allow HTTP from anywhere
  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTPS from anywhere
  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name        = "voxpop-${var.environment}-alb-sg"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  )
}

# Security Group for future database (RDS, etc.)
resource "aws_security_group" "database" {
  name        = "voxpop-${var.environment}-database-sg"
  description = "Security group for database instances"
  vpc_id      = var.vpc_id

  # Allow PostgreSQL from ECS tasks only
  ingress {
    description     = "PostgreSQL from ECS tasks"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  # Allow PostgreSQL from Bastion Host (SSM Tunnel)
  dynamic "ingress" {
    for_each = var.bastion_sg_id != "" ? [1] : []
    content {
      description     = "PostgreSQL from Bastion Host"
      from_port       = 5432
      to_port         = 5432
      protocol        = "tcp"
      security_groups = [var.bastion_sg_id]
    }
  }

  # No outbound rules needed for database
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name        = "voxpop-${var.environment}-database-sg"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  )
}


