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
  bastion_sg_id       = module.bastion.security_group_id

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


# Bastion Host Module (SSM Access)
module "bastion" {
  source = "../../modules/bastion"

  environment = var.environment
  vpc_id      = module.network.vpc_id
  subnet_id   = module.network.public_subnet_ids[0] # Place in public subnet for SSM access (no NAT GW)

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

  # No db_name - let EF migrations create identitydb and coredb
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


# --------------------------------------------------------------------------------------------------
# Secrets Manager
# --------------------------------------------------------------------------------------------------



# Identity DB Connection String Secret
resource "aws_secretsmanager_secret" "identity_db_connection" {
  name                    = "voxpop-${var.environment}-identity-db-connection-${formatdate("YYYYMMDDhhmm", timestamp())}"
  recovery_window_in_days = 0
  tags = {
    Project = "voxpop"
  }
}

resource "aws_secretsmanager_secret_version" "identity_db_connection" {
  secret_id     = aws_secretsmanager_secret.identity_db_connection.id
  secret_string = "Host=${module.rds.address};Port=${module.rds.port};Database=identity_db;Username=${var.db_username};Password=${var.db_password}"
}

# Core DB Connection String Secret
resource "aws_secretsmanager_secret" "core_db_connection" {
  name                    = "voxpop-${var.environment}-core-db-connection-${formatdate("YYYYMMDDhhmm", timestamp())}"
  recovery_window_in_days = 0
  tags = {
    Project = "voxpop"
  }
}

resource "aws_secretsmanager_secret_version" "core_db_connection" {
  secret_id     = aws_secretsmanager_secret.core_db_connection.id
  secret_string = "Host=${module.rds.address};Port=${module.rds.port};Database=core_db;Username=${var.db_username};Password=${var.db_password}"
}

# --------------------------------------------------------------------------------------------------
# Twilio Secrets
# --------------------------------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "twilio_account_sid" {
  name                    = "voxpop-${var.environment}-twilio-account-sid-${formatdate("YYYYMMDDhhmm", timestamp())}"
  recovery_window_in_days = 0
  tags                    = { Project = "voxpop" }
}
resource "aws_secretsmanager_secret_version" "twilio_account_sid" {
  secret_id     = aws_secretsmanager_secret.twilio_account_sid.id
  secret_string = var.twilio_account_sid
}

resource "aws_secretsmanager_secret" "twilio_auth_token" {
  name                    = "voxpop-${var.environment}-twilio-auth-token-${formatdate("YYYYMMDDhhmm", timestamp())}"
  recovery_window_in_days = 0
  tags                    = { Project = "voxpop" }
}
resource "aws_secretsmanager_secret_version" "twilio_auth_token" {
  secret_id     = aws_secretsmanager_secret.twilio_auth_token.id
  secret_string = var.twilio_auth_token
}

resource "aws_secretsmanager_secret" "twilio_service_sid" {
  name                    = "voxpop-${var.environment}-twilio-service-sid-${formatdate("YYYYMMDDhhmm", timestamp())}"
  recovery_window_in_days = 0
  tags                    = { Project = "voxpop" }
}
resource "aws_secretsmanager_secret_version" "twilio_service_sid" {
  secret_id     = aws_secretsmanager_secret.twilio_service_sid.id
  secret_string = var.twilio_service_sid
}

# JWT Secret Key
resource "aws_secretsmanager_secret" "jwt_key" {
  name                    = "voxpop-${var.environment}-jwt-key-${formatdate("YYYYMMDDhhmm", timestamp())}"
  recovery_window_in_days = 0
  tags                    = { Project = "voxpop" }
}
resource "aws_secretsmanager_secret_version" "jwt_key" {
  secret_id     = aws_secretsmanager_secret.jwt_key.id
  secret_string = var.jwt_key
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

  # Give 3 minutes for migrations to complete before health checks start
  health_check_grace_period_seconds = 180

  environment_variables = {
    ASPNETCORE_ENVIRONMENT = "Beta"
    SERVICE_NAME           = "voxpop-identity"
    ENVIRONMENT            = var.environment
  }

  secrets = {
    ConnectionStrings__IdentityDb = aws_secretsmanager_secret.identity_db_connection.arn
    Twilio__AccountSid            = aws_secretsmanager_secret.twilio_account_sid.arn
    Twilio__AuthToken             = aws_secretsmanager_secret.twilio_auth_token.arn
    Twilio__ServiceSid            = aws_secretsmanager_secret.twilio_service_sid.arn
    Jwt__Key                      = aws_secretsmanager_secret.jwt_key.arn
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

  # Give 3 minutes for migrations/seeding to complete before health checks start
  health_check_grace_period_seconds = 180

  environment_variables = {
    ASPNETCORE_ENVIRONMENT = "Beta"
    SERVICE_NAME           = "voxpop-core"
    ENVIRONMENT            = var.environment
  }

  secrets = {
    ConnectionStrings__CoreDb = aws_secretsmanager_secret.core_db_connection.arn
    Jwt__Key                  = aws_secretsmanager_secret.jwt_key.arn
  }

  tags = {
    Project = "voxpop"
  }
}
