# CloudWatch Log Group for container logs
resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${var.service_name}-${var.environment}"
  retention_in_days = 7 # Short retention for cost optimization

  tags = {
    Name = "${var.service_name}-${var.environment}-logs"
  }
}

# ECS Task Definition
resource "aws_ecs_task_definition" "this" {
  family                   = "${var.service_name}-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = var.task_execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = var.service_name
      image     = var.container_image
      essential = true

      portMappings = [
        {
          containerPort = var.container_port
          protocol      = "tcp"
        }
      ]

      environment = [
        for key, value in var.environment_variables : {
          name  = key
          value = value
        }
      ]

      secrets = [
        for key, value in var.secrets : {
          name      = key
          valueFrom = value
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.this.name
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Name = "${var.service_name}-${var.environment}-task-definition"
  }
}

# ECS Service
resource "aws_ecs_service" "this" {
  name            = "${var.service_name}-${var.environment}"
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = var.security_group_ids
    assign_public_ip = var.assign_public_ip
  }

  # Load balancer configuration (optional)
  dynamic "load_balancer" {
    for_each = var.target_group_arn != "" ? [1] : []
    content {
      target_group_arn = var.target_group_arn
      container_name   = var.service_name
      container_port   = var.container_port
    }
  }

  # Health check grace period - gives time for migrations/seeding before health checks start
  health_check_grace_period_seconds = var.health_check_grace_period_seconds

  # Enable ECS Exec for debugging (optional, can be disabled for production)
  enable_execute_command = true

  tags = {
    Name = "${var.service_name}-${var.environment}-service"
  }

  # Ignore changes to desired_count for auto-scaling
  # Ignore task_definition to allow external CD pipeline to manage images
  lifecycle {
    ignore_changes = [desired_count, task_definition]
  }
}
