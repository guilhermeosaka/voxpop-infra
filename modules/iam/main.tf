# ECS Task Execution Role
# This role is used by ECS to pull images and write logs
resource "aws_iam_role" "ecs_task_execution" {
  name = "voxpop-${var.environment}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "voxpop-${var.environment}-ecs-task-execution-role"
  }
}

# Attach AWS managed policy for ECS task execution
resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS Task Role
# This role is used by the application running in the container
resource "aws_iam_role" "ecs_task" {
  name = "voxpop-${var.environment}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "voxpop-${var.environment}-ecs-task-role"
  }
}

# Example policy for ECS task (customize based on your application needs)
resource "aws_iam_role_policy" "ecs_task" {
  name = "voxpop-${var.environment}-ecs-task-policy"
  role = aws_iam_role.ecs_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::voxpop-${var.environment}-*",
          "arn:aws:s3:::voxpop-${var.environment}-*/*"
        ]
      }
    ]
  })
}

# GitHub Actions OIDC Provider
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  tags = {
    Name = "github-actions-oidc-provider"
  }
}

# GitHub Actions Role for Terraform
resource "aws_iam_role" "github_actions" {
  name = "voxpop-${var.environment}-github-actions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = [
              for repo in var.github_repos : "repo:${var.github_org}/${repo}:*"
            ]
          }
        }
      }
    ]
  })

  tags = {
    Name = "voxpop-${var.environment}-github-actions-role"
  }
}

# GitHub Actions Policy for Terraform operations
resource "aws_iam_role_policy" "github_actions_terraform" {
  name = "voxpop-${var.environment}-github-actions-terraform-policy"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:*",
          "ecs:*",
          "ecr:*",
          "logs:*",
          "iam:*",
          "s3:*",
          "rds:*",
          "cloudwatch:*",
          "elasticloadbalancing:*",
          "cloudfront:*",
          "secretsmanager:*"
        ]
        Resource = "*"
      }
    ]
  })
}

# GitHub Actions Policy for ECS deployments
resource "aws_iam_role_policy" "github_actions_ecs_deploy" {
  name = "voxpop-${var.environment}-github-actions-ecs-deploy-policy"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecs:UpdateService",
          "ecs:DescribeServices",
          "ecs:DescribeTaskDefinition",
          "ecs:RegisterTaskDefinition",
          "ecs:ListTasks",
          "ecs:DescribeTasks"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = [
          aws_iam_role.ecs_task_execution.arn,
          aws_iam_role.ecs_task.arn
        ]
      }
    ]
  })
}
# Allow ECS Task Execution role to read secrets
resource "aws_iam_role_policy" "ecs_execution_secrets" {
  name = "voxpop-${var.environment}-ecs-execution-secrets-policy"
  role = aws_iam_role.ecs_task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "kms:Decrypt"
        ]
        Resource = [
          "arn:aws:secretsmanager:*:*:secret:voxpop-${var.environment}-db-password-*",

        ]
      }
    ]
  })
}
