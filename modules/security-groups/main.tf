# Security Group for ECS Tasks
resource "aws_security_group" "ecs_tasks" {
  name        = "voxpop-${var.environment}-ecs-tasks-sg"
  description = "Security group for ECS tasks"
  vpc_id      = var.vpc_id

  # Allow HTTP from ALB
  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
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

# Security Group for RabbitMQ
resource "aws_security_group" "rabbitmq" {
  count       = var.enable_rabbitmq ? 1 : 0
  name        = "voxpop-${var.environment}-rabbitmq-sg"
  description = "Security group for RabbitMQ instances"
  vpc_id      = var.vpc_id

  # Allow AMQP from ECS tasks
  ingress {
    description     = "AMQP from ECS tasks"
    from_port       = 5672
    to_port         = 5672
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  # Allow RabbitMQ management UI from allowed CIDR blocks
  ingress {
    description = "RabbitMQ management UI"
    from_port   = 15672
    to_port     = 15672
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
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
      Name        = "voxpop-${var.environment}-rabbitmq-sg"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  )
}
