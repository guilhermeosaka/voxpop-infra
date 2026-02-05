# Virtual Private Cloud
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr # CIDR (Classless Inter-Domain Routing) defines the IP address range for your network.
  enable_dns_support   = true         # Enables the Amazon-provided DNS server (the "Route 53 Resolver").
  enable_dns_hostnames = true         # Ensures that instances launched in this VPC get a public DNS hostname (like ec2-54-x-x-x.compute-1.amazonaws.com) in addition to their IP address.

  tags = {
    Name = "voxpop-${var.environment}-vpc"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "voxpop-${var.environment}-igw"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "public" {
  count                   = var.availability_zone_count
  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(aws_vpc.this.cidr_block, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "voxpop-${var.environment}-subnet-public-${count.index + 1}"
  }
}

resource "aws_subnet" "private" {
  count             = var.availability_zone_count
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(aws_vpc.this.cidr_block, 8, count.index + 10)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "voxpop-${var.environment}-subnet-private-${count.index + 1}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "voxpop-${var.environment}-rt-public"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "voxpop-${var.environment}-rt-private"
  }
}

resource "aws_route_table_association" "public" {
  count          = var.availability_zone_count
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = var.availability_zone_count
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  count             = var.enable_vpc_flow_logs ? 1 : 0
  name              = "/aws/vpc/voxpop-${var.environment}"
  retention_in_days = 7 # Short retention for cost optimization

  tags = {
    Name = "voxpop-${var.environment}-vpc-flow-logs"
  }
}

resource "aws_iam_role" "vpc_flow_logs" {
  count = var.enable_vpc_flow_logs ? 1 : 0
  name  = "voxpop-${var.environment}-vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "voxpop-${var.environment}-vpc-flow-logs-role"
  }
}

resource "aws_iam_role_policy" "vpc_flow_logs" {
  count = var.enable_vpc_flow_logs ? 1 : 0
  name  = "voxpop-${var.environment}-vpc-flow-logs-policy"
  role  = aws_iam_role.vpc_flow_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_flow_log" "vpc" {
  count                    = var.enable_vpc_flow_logs ? 1 : 0
  iam_role_arn             = aws_iam_role.vpc_flow_logs[0].arn
  log_destination          = aws_cloudwatch_log_group.vpc_flow_logs[0].arn
  traffic_type             = "ALL"
  vpc_id                   = aws_vpc.this.id
  max_aggregation_interval = 600 # 10 minutes for cost optimization

  tags = {
    Name = "voxpop-${var.environment}-vpc-flow-log"
  }
}

# VPC Endpoints for cost-effective AWS service access
# S3 Gateway Endpoint (free)
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.us-east-1.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = concat(
    [aws_route_table.public.id],
    [aws_route_table.private.id]
  )

  tags = {
    Name = "voxpop-${var.environment}-s3-endpoint"
  }
}

# Note: ECR VPC endpoints removed for cost optimization in beta
# ECS tasks in public subnets can pull images via internet

# --------------------------------------------------------------------------------------------------
# EC2 Instance Connect Endpoint (Secure Tunneling)
# --------------------------------------------------------------------------------------------------

# Security Group for the EIC Endpoint
resource "aws_security_group" "eic_endpoint" {
  name        = "voxpop-${var.environment}-eic-endpoint-sg"
  description = "Security group for EC2 Instance Connect Endpoint"
  vpc_id      = aws_vpc.this.id

  # Allow outbound traffic to the database port (5432)
  # The tunnel initiates the connection to the DB
  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr] # Allow connecting to anything in VPC on port 5432
    description = "Allow EIC Endpoint to connect to Postgres"
  }

  tags = {
    Name = "voxpop-${var.environment}-eic-endpoint-sg"
  }
}

# The Endpoint itself
resource "aws_ec2_instance_connect_endpoint" "this" {
  subnet_id          = aws_subnet.private[0].id # Place in the first private subnet
  security_group_ids = [aws_security_group.eic_endpoint.id]

  tags = {
    Name = "voxpop-${var.environment}-eic-endpoint"
  }
}

