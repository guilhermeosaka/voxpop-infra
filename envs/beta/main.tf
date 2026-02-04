# Network Module
module "network" {
  source = "../../modules/network"

  environment             = var.environment
  vpc_cidr                = var.vpc_cidr
  availability_zone_count = var.availability_zone_count
  enable_vpc_flow_logs    = var.enable_vpc_flow_logs
  enable_nat_gateway      = false # No NAT Gateway for cost savings

  tags = {
    Project = "voxpop"
  }
}

# Security Groups Module
module "security_groups" {
  source = "../../modules/security-groups"

  environment         = var.environment
  vpc_id              = module.network.vpc_id
  vpc_cidr            = module.network.vpc_cidr
  allowed_cidr_blocks = var.allowed_cidr_blocks
  enable_rabbitmq     = var.enable_rabbitmq

  tags = {
    Project = "voxpop"
  }
}

# IAM Module
module "iam" {
  source = "../../modules/iam"

  environment  = var.environment
  github_org   = var.github_org
  github_repos = var.github_repos

  tags = {
    Project = "voxpop"
  }
}

# RDS Postgres Module
module "rds" {
  source = "../../modules/rds"

  environment        = var.environment
  vpc_id             = module.network.vpc_id
  subnet_ids         = module.network.private_subnet_ids
  security_group_ids = [module.security_groups.database_sg_id]

  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password

  instance_class    = "db.t4g.micro"
  allocated_storage = 20
  multi_az          = false

  tags = {
    Project = "voxpop"
  }
}

# ECS Cluster Module
module "ecs_cluster" {
  source = "../../modules/ecs-cluster"

  environment               = var.environment
  cluster_name              = "voxpop"
  enable_container_insights = false

  tags = {
    Project = "voxpop"
  }
}

# RabbitMQ Module (Optional)
module "rabbitmq" {
  count  = var.enable_rabbitmq ? 1 : 0
  source = "../../modules/rabbitmq"

  environment             = var.environment
  vpc_id                  = module.network.vpc_id
  cluster_id              = module.ecs_cluster.cluster_id
  subnet_ids              = module.network.private_subnet_ids
  security_group_ids      = [module.security_groups.rabbitmq_sg_id]
  task_execution_role_arn = module.iam.ecs_task_execution_role_arn
  task_role_arn           = module.iam.ecs_task_role_arn

  rabbitmq_username = var.rabbitmq_username
  rabbitmq_password = var.rabbitmq_password

  tags = {
    Project = "voxpop"
  }
}

# Application Load Balancer
module "alb" {
  source = "../../modules/alb"

  environment        = var.environment
  vpc_id             = module.network.vpc_id
  subnet_ids         = module.network.public_subnet_ids
  security_group_ids = [module.security_groups.alb_sg_id]

  identity_port              = var.identity_container_port
  core_port                  = var.core_container_port
  identity_health_check_path = "/health"
  core_health_check_path     = "/health"

  certificate_arn            = var.alb_certificate_arn
  enable_deletion_protection = false

  tags = {
    Project = "voxpop"
  }
}

# CloudFront Distribution (Free HTTPS)
module "cloudfront" {
  source = "../../modules/cloudfront"

  environment  = var.environment
  alb_dns_name = module.alb.alb_dns_name

  # Don't cache API responses by default
  default_ttl = 0
  max_ttl     = 0

  # Use cheapest price class (US, Canada, Europe)
  price_class = "PriceClass_100"

  tags = {
    Project = "voxpop"
  }
}

# Identity Service (voxpop-identity)
module "identity_service" {
  source = "../../modules/ecs-service"

  environment             = var.environment
  service_name            = "voxpop-identity"
  cluster_id              = module.ecs_cluster.cluster_id
  cluster_name            = module.ecs_cluster.cluster_name
  subnet_ids              = module.network.public_subnet_ids
  security_group_ids      = [module.security_groups.ecs_tasks_sg_id]
  task_execution_role_arn = module.iam.ecs_task_execution_role_arn
  task_role_arn           = module.iam.ecs_task_role_arn

  container_image  = var.identity_container_image
  container_port   = var.identity_container_port
  cpu              = var.identity_cpu
  memory           = var.identity_memory
  desired_count    = 1
  assign_public_ip = true
  target_group_arn = module.alb.identity_target_group_arn

  environment_variables = {
    ENVIRONMENT  = var.environment
    SERVICE_NAME = "voxpop-identity"
    DATABASE_URL = "postgresql://${var.db_username}:${var.db_password}@${module.rds.address}:${module.rds.port}/${module.rds.database_name}"
    RABBITMQ_URL = var.enable_rabbitmq ? module.rabbitmq[0].connection_string : ""
  }

  tags = {
    Project = "voxpop"
  }
}

# Core Service (voxpop-core)
module "core_service" {
  source = "../../modules/ecs-service"

  environment             = var.environment
  service_name            = "voxpop-core"
  cluster_id              = module.ecs_cluster.cluster_id
  cluster_name            = module.ecs_cluster.cluster_name
  subnet_ids              = module.network.public_subnet_ids
  security_group_ids      = [module.security_groups.ecs_tasks_sg_id]
  task_execution_role_arn = module.iam.ecs_task_execution_role_arn
  task_role_arn           = module.iam.ecs_task_role_arn

  container_image  = var.core_container_image
  container_port   = var.core_container_port
  cpu              = var.core_cpu
  memory           = var.core_memory
  desired_count    = 1
  assign_public_ip = true
  target_group_arn = module.alb.core_target_group_arn

  environment_variables = {
    ENVIRONMENT  = var.environment
    SERVICE_NAME = "voxpop-core"
    DATABASE_URL = "postgresql://${var.db_username}:${var.db_password}@${module.rds.address}:${module.rds.port}/${module.rds.database_name}"
    RABBITMQ_URL = var.enable_rabbitmq ? module.rabbitmq[0].connection_string : ""
  }

  tags = {
    Project = "voxpop"
  }
}
