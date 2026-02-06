# IAM Role for SSM
resource "aws_iam_role" "bastion" {
  name = "voxpop-${var.environment}-bastion-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.bastion.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "bastion" {
  name = "voxpop-${var.environment}-bastion-profile"
  role = aws_iam_role.bastion.name
}

# Security Group
resource "aws_security_group" "bastion" {
  name        = "voxpop-${var.environment}-bastion-sg"
  description = "Security group for Bastion Host"
  vpc_id      = var.vpc_id

  # No ingress rules needed! SSM Agent initiates connection.

  # Allow all outbound traffic (needed for SSM Agent to talk to AWS)
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
      Name = "voxpop-${var.environment}-bastion-sg"
    }
  )
}

# Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-arm64"] # Use ARM64 for t4g instances
  }
}

# Bastion Instance
resource "aws_instance" "this" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id

  iam_instance_profile   = aws_iam_instance_profile.bastion.name
  vpc_security_group_ids = [aws_security_group.bastion.id]

  # Enable T4g unlimited (negligible cost for nano, avoids throttling)
  credit_specification {
    cpu_credits = "standard"
  }

  tags = merge(
    var.tags,
    {
      Name = "voxpop-${var.environment}-bastion"
    }
  )
}
