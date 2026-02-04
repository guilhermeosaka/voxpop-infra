# RabbitMQ Module (Optional)

# CloudWatch Log Group for RabbitMQ
resource "aws_cloudwatch_log_group" "rabbitmq" {
  name              = "/ecs/voxpop-${var.environment}-rabbitmq"
  retention_in_days = 7

  tags = merge(
    var.tags,
    {
      Name        = "voxpop-${var.environment}-rabbitmq-logs"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  )
}

# ECS Task Definition for RabbitMQ
resource "aws_ecs_task_definition" "rabbitmq" {
  family                   = "voxpop-${var.environment}-rabbitmq"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = var.task_execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = "rabbitmq"
      image     = "rabbitmq:${var.rabbitmq_version}-management"
      essential = true

      portMappings = [
        {
          containerPort = 5672
          protocol      = "tcp"
          name          = "amqp"
        },
        {
          containerPort = 15672
          protocol      = "tcp"
          name          = "management"
        }
      ]

      environment = [
        {
          name  = "RABBITMQ_DEFAULT_USER"
          value = var.rabbitmq_username
        },
        {
          name  = "RABBITMQ_DEFAULT_PASS"
          value = var.rabbitmq_password
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.rabbitmq.name
          "awslogs-region"        = data.aws_region.current.id
          "awslogs-stream-prefix" = "rabbitmq"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "rabbitmq-diagnostics -q ping"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = merge(
    var.tags,
    {
      Name        = "voxpop-${var.environment}-rabbitmq-task"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  )
}

# ECS Service for RabbitMQ
resource "aws_ecs_service" "rabbitmq" {
  name            = "voxpop-${var.environment}-rabbitmq"
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.rabbitmq.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = var.security_group_ids
    assign_public_ip = false # Private subnet, no public IP needed
  }

  # Service discovery (optional, for internal DNS)
  dynamic "service_registries" {
    for_each = var.enable_service_discovery ? [1] : []
    content {
      registry_arn = aws_service_discovery_service.rabbitmq[0].arn
    }
  }

  tags = merge(
    var.tags,
    {
      Name        = "voxpop-${var.environment}-rabbitmq-service"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  )
}

# Service Discovery (optional)
resource "aws_service_discovery_private_dns_namespace" "this" {
  count = var.enable_service_discovery ? 1 : 0
  name  = "${var.environment}.voxpop.local"
  vpc   = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name        = "voxpop-${var.environment}-service-discovery"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  )
}

resource "aws_service_discovery_service" "rabbitmq" {
  count = var.enable_service_discovery ? 1 : 0
  name  = "rabbitmq"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.this[0].id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    # failure_threshold is deprecated and always set to 1 by AWS
  }

  tags = merge(
    var.tags,
    {
      Name        = "voxpop-${var.environment}-rabbitmq-discovery"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  )
}

# Data source for current region
data "aws_region" "current" {}
