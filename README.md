# Voxpop Infrastructure

Production-ready Terraform infrastructure for the Voxpop application on AWS, optimized for cost-effectiveness in beta while maintaining best practices for future production deployment.

## 📋 Table of Contents

- [Architecture Overview](#architecture-overview)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Project Structure](#project-structure)
- [Deployment](#deployment)
- [Cost Optimization](#cost-optimization)
- [CI/CD with GitHub Actions](#cicd-with-github-actions)
- [Accessing Your Application](#accessing-your-application)
- [Troubleshooting](#troubleshooting)

## 🏗️ Architecture Overview

### Beta Environment (Cost-Optimized)
- **VPC**: Custom VPC with public and private subnets across 2 availability zones
- **ECS Fargate**: Serverless container execution (no EC2 instances to manage)
- **No NAT Gateway**: ECS tasks run in public subnets to save ~$32/month
- **No ALB**: Direct access via public IP to save ~$16/month
- **VPC Endpoints**: Free S3 gateway endpoint + ECR endpoints for Docker image pulls
- **Estimated Cost**: ~$1-2/month + ECS task costs (~$15-30/month for 1 task)

### Production-Ready Features
- ✅ Remote state management with S3 + local lockfile
- ✅ Modular infrastructure (network, security, IAM, ECS)
- ✅ Comprehensive tagging strategy
- ✅ VPC Flow Logs (optional, can be disabled for cost savings)
- ✅ GitHub Actions CI/CD with OIDC (no access keys)
- ✅ Container Insights for monitoring
- ✅ CloudWatch logging for all services

## 📦 Prerequisites

1. **AWS Account** with appropriate permissions
2. **Terraform** >= 1.14 ([Install](https://www.terraform.io/downloads))
3. **AWS CLI** ([Install](https://aws.amazon.com/cli/))
4. **GitHub Account** (for CI/CD)

## 🚀 Quick Start

### Step 1: Create Backend Resources

The S3 bucket for Terraform state must be created manually first:

```bash
# Create S3 bucket for state
aws s3api create-bucket --bucket voxpop-terraform-state --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning --bucket voxpop-terraform-state --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption --bucket voxpop-terraform-state --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'
```

### Step 2: Configure Terraform

```bash
cd envs/beta

# Copy example variables
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your values
# IMPORTANT: Restrict allowed_cidr_blocks to your IP for security
```

### Step 3: Enable Remote Backend

Uncomment the backend configuration in `envs/beta/providers.tf`:

```hcl
backend "s3" {
  bucket       = "voxpop-terraform-state"
  key          = "envs/beta/terraform.tfstate"
  region       = "us-east-1"
  use_lockfile = true
  encrypt      = true
}
```

### Step 4: Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the infrastructure
terraform apply
```

### Step 5: Setup GitHub Actions (Optional)

1. **Get the GitHub Actions Role ARN** from Terraform outputs:
   ```bash
   terraform output github_actions_role_arn
   ```

2. **Add to GitHub Secrets**:
   - Go to your repository → Settings → Secrets and variables → Actions
   - Add secret: `AWS_ROLE_ARN` with the value from step 1

3. **Push to trigger workflows**:
   - Create a PR → Terraform plan runs automatically
   - Merge to main → Terraform apply runs automatically

## 📁 Project Structure

```

├── backend.tf                 # Backend configuration (commented out initially)
├── providers.tf               # Provider version constraints
├── versions.tf                # Terraform version constraints
├── .gitignore                 # Ignore sensitive files
│
├── modules/                   # Reusable Terraform modules
│   ├── network/               # VPC, subnets, routing, VPC endpoints
│   ├── security-groups/       # Security groups for ECS and database
│   ├── iam/                   # IAM roles for ECS and GitHub Actions
│   ├── ecs-cluster/           # ECS cluster with Fargate
│   └── ecs-service/           # ECS service, task definition, logging
│
└── envs/                      # Environment-specific configurations
    └── beta/                  # Beta environment
        ├── main.tf            # Module composition
        ├── variables.tf       # Input variables
        ├── outputs.tf         # Output values
        ├── providers.tf       # Provider and backend config
        └── terraform.tfvars.example  # Example variable values
```

## 🚢 Deployment

### Local Deployment

```bash
cd envs/beta
terraform init
terraform plan
terraform apply
```

### CI/CD Deployment

1. **Create a Pull Request** with infrastructure changes
2. GitHub Actions runs `terraform plan` and comments on the PR
3. **Review the plan** in the PR comment
4. **Merge the PR** to main
5. GitHub Actions automatically runs `terraform apply`

## 💰 Cost Optimization

### Beta Environment Strategies

| Resource | Strategy | Savings |
|----------|----------|---------|
| NAT Gateway | Use public subnets for ECS tasks | ~$32/month |
| Load Balancer | Direct access via public IP | ~$16/month |
| VPC Flow Logs | Disabled by default | ~$0.50/GB |
| ECS Tasks | Minimum CPU/memory (256/512) | ~50% vs larger sizes |
| Log Retention | 7 days instead of 30+ | ~70% on log storage |

**Total Beta Cost**: ~$1-2/month + ECS task costs (~$15-30/month for 1 task)

### Production Recommendations

When moving to production, consider adding:
- **NAT Gateway**: For better security (private subnets)
- **Application Load Balancer**: For zero-downtime deployments
- **Auto Scaling**: For handling traffic spikes
- **Multi-AZ**: For high availability
- **CloudWatch Alarms**: For proactive monitoring

## 🔄 CI/CD with GitHub Actions

### Workflows

1. **terraform-plan.yml**: Runs on pull requests
   - Validates Terraform syntax
   - Generates execution plan
   - Posts plan as PR comment

2. **terraform-apply.yml**: Runs on merge to main
   - Applies infrastructure changes
   - Updates ECS services

3. **ecs-deploy.yml**: Deploys application
   - Builds Docker image
   - Pushes to Amazon ECR
   - Updates ECS task definition
   - Deploys new version

### OIDC Authentication

No AWS access keys needed! GitHub Actions uses OIDC to assume an IAM role:
- More secure (no long-lived credentials)
- Automatic credential rotation
- Fine-grained permissions

## 🌐 Accessing Your Application

### Get ECS Task Public IP

```bash
# Get cluster and service names
terraform output ecs_cluster_name
terraform output ecs_service_name

# List tasks
aws ecs list-tasks \
  --cluster <cluster_name> \
  --service-name <service_name>

# Get task details (including public IP)
aws ecs describe-tasks \
  --cluster <cluster_name> \
  --tasks <task_arn> \
  --query 'tasks[0].attachments[0].details[?name==`networkInterfaceId`].value' \
  --output text | xargs -I {} aws ec2 describe-network-interfaces \
  --network-interface-ids {} \
  --query 'NetworkInterfaces[0].Association.PublicIp' \
  --output text
```

### Access Your Application

```bash
# If using default nginx image
curl http://<public_ip>

# If using custom port (e.g., 8080)
curl http://<public_ip>:8080
```

## 🔧 Troubleshooting

### Task Won't Start

**Check ECS service events**:
```bash
aws ecs describe-services \
  --cluster <cluster_name> \
  --services <service_name> \
  --query 'services[0].events[0:5]'
```

**Common issues**:
- Image pull errors: Check ECR permissions
- Resource limits: Increase CPU/memory
- Security group: Ensure egress rules allow HTTPS (443)

### Can't Access Application

**Check security group**:
- Ensure your IP is in `allowed_cidr_blocks`
- Verify ingress rules allow your application port

**Check task is running**:
```bash
aws ecs list-tasks --cluster <cluster_name> --service-name <service_name>
```

### Terraform State Locked

If Terraform state is locked:
```bash
# Force unlock (use with caution)
terraform force-unlock <lock_id>
```

## 📚 Additional Resources

- [Terraform AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS ECS Best Practices](https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/)
- [GitHub Actions OIDC with AWS](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)

## 🤝 Contributing

1. Create a feature branch
2. Make your changes
3. Create a pull request
4. Review the Terraform plan in PR comments
5. Merge after approval

## 📄 License

[Your License Here]
