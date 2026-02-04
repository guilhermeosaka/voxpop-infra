# Voxpop Infrastructure - First Deployment Guide

## Prerequisites Checklist

Before running Terraform, ensure you have:

- [x] AWS Account with appropriate permissions
- [x] AWS CLI installed and configured
- [x] Terraform >= 1.14 installed
- [x] S3 bucket created for Terraform state (`voxpop-terraform-state`)
- [ ] Docker images built and pushed to ECR (or use nginx:latest for testing)
- [ ] AWS credentials configured locally

---

## Step 1: Configure AWS Credentials

Make sure your AWS credentials are configured:

```bash
# Check if credentials are set
aws sts get-caller-identity

# If not configured, set them:
aws configure
# Enter: Access Key ID, Secret Access Key, Region (us-east-1)
```

---

## Step 2: Create terraform.tfvars

```bash
cd envs/beta

# Copy the example file
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
notepad terraform.tfvars  # or use your preferred editor
```

### Required Changes in terraform.tfvars:

1. **Database Password** (REQUIRED):
   ```hcl
   db_password = "YourSecurePassword123!"
   ```

2. **Container Images** (REQUIRED for real deployment):
   ```hcl
   identity_container_image = "your-account.dkr.ecr.us-east-1.amazonaws.com/voxpop-identity:latest"
   core_container_image = "your-account.dkr.ecr.us-east-1.amazonaws.com/voxpop-core:latest"
   ```
   
   **For initial testing**, you can use:
   ```hcl
   identity_container_image = "nginx:latest"
   core_container_image = "nginx:latest"
   ```

3. **Security** (RECOMMENDED):
   ```hcl
   # Replace with your IP address
   allowed_cidr_blocks = ["YOUR.IP.ADDRESS/32"]
   ```
   
   Find your IP: `curl ifconfig.me`

---

## Step 3: Initialize Terraform

```bash
# Make sure you're in envs/beta directory
cd c:\Users\osaka\Projects\voxpop\voxpop.infra\envs\beta

# Initialize Terraform (downloads providers and modules)
terraform init
```

**Expected output:**
```
Initializing modules...
- alb in ../../modules/alb
- core_service in ../../modules/ecs-service
- ecs_cluster in ../../modules/ecs-cluster
- iam in ../../modules/iam
- identity_service in ../../modules/ecs-service
- network in ../../modules/network
- rds in ../../modules/rds
- security_groups in ../../modules/security-groups

Initializing the backend...
Successfully configured the backend "s3"!

Terraform has been successfully initialized!
```

---

## Step 4: Validate Configuration

```bash
# Check for syntax errors
terraform validate
```

**Expected output:**
```
Success! The configuration is valid.
```

---

## Step 5: Plan the Deployment

```bash
# See what Terraform will create
terraform plan
```

This will show you:
- **Resources to be created**: ~40-50 resources
- **Estimated costs**: Review the resources
- **Any errors**: Fix before applying

**Key resources that will be created:**
- VPC with public/private subnets
- Application Load Balancer
- 2 ECS Services (identity + core)
- RDS Postgres database
- Security groups
- IAM roles
- CloudWatch log groups

---

## Step 6: Apply the Configuration

```bash
# Deploy the infrastructure
terraform apply
```

Type `yes` when prompted.

**Deployment time**: ~5-10 minutes

---

## Step 7: Get Your Endpoints

After successful deployment:

```bash
# Get ALB DNS name
terraform output alb_dns_name

# Get API endpoints
terraform output api_endpoints

# Get database endpoint
terraform output database_endpoint
```

**Example output:**
```
alb_dns_name = "voxpop-beta-alb-1234567890.us-east-1.elb.amazonaws.com"

api_endpoints = {
  "core" = "http://voxpop-beta-alb-1234567890.us-east-1.elb.amazonaws.com/core"
  "identity" = "http://voxpop-beta-alb-1234567890.us-east-1.elb.amazonaws.com/identity"
}
```

---

## Step 8: Test Your Services

```bash
# Get the ALB URL
$ALB_URL = terraform output -raw alb_url

# Test identity service
curl "$ALB_URL/identity"

# Test core service
curl "$ALB_URL/core"
```

---

## Troubleshooting

### Issue: "Error: No valid credential sources found"

**Solution:**
```bash
# Configure AWS credentials
aws configure

# Or set environment variables
$env:AWS_ACCESS_KEY_ID="your-access-key"
$env:AWS_SECRET_ACCESS_KEY="your-secret-key"
$env:AWS_DEFAULT_REGION="us-east-1"
```

### Issue: "Error: creating S3 Bucket: BucketAlreadyExists"

**Solution:** The S3 bucket name must be globally unique. Update in `providers.tf`:
```hcl
backend "s3" {
  bucket = "voxpop-terraform-state-YOUR-UNIQUE-SUFFIX"
  # ...
}
```

### Issue: Services showing as "Unhealthy" in ALB

**Reasons:**
1. Container images don't have `/health` endpoint
2. Container failing to start
3. Wrong port configuration

**Check logs:**
```bash
aws logs tail /ecs/voxpop-identity-beta --follow
aws logs tail /ecs/voxpop-core-beta --follow
```

### Issue: "Error: error creating RDS DB Instance: InvalidParameterValue"

**Solution:** Make sure `db_password` meets AWS requirements:
- At least 8 characters
- Contains uppercase, lowercase, numbers
- No special characters like `@`, `/`, `"`

---

## Next Steps After Deployment

1. **Update Vercel Environment Variables:**
   ```
   NEXT_PUBLIC_API_URL=http://your-alb-dns
   NEXT_PUBLIC_IDENTITY_API=http://your-alb-dns/identity
   NEXT_PUBLIC_CORE_API=http://your-alb-dns/core
   ```

2. **Build and Deploy Your Services:**
   - Build Docker images for identity and core services
   - Push to ECR
   - Update `terraform.tfvars` with real image URIs
   - Run `terraform apply` again

3. **Enable HTTPS (Optional):**
   - Request ACM certificate
   - Update `alb_certificate_arn` in `terraform.tfvars`
   - Run `terraform apply`

4. **Set up CI/CD:**
   - Use the GitHub Actions role ARN from outputs
   - Configure GitHub Actions workflows

---

## Cost Estimate (First Month)

| Resource | Estimated Cost |
|----------|----------------|
| ECS Tasks (2 services) | ~$20-30 |
| RDS Postgres (t4g.micro) | ~$12 (or free tier) |
| ALB | ~$18-21 |
| CloudWatch Logs | ~$1 |
| **Total** | **~$51-64/month** |

---

## Clean Up (If Needed)

To destroy all resources:

```bash
terraform destroy
```

Type `yes` when prompted. This will delete all infrastructure.

⚠️ **Warning:** This is irreversible! Make sure you have backups of your database.

---

## Summary

✅ **Configure** `terraform.tfvars` with your values  
✅ **Initialize** with `terraform init`  
✅ **Validate** with `terraform validate`  
✅ **Plan** with `terraform plan`  
✅ **Deploy** with `terraform apply`  
✅ **Test** your endpoints  
✅ **Update** Vercel with ALB DNS  

Good luck with your deployment! 🚀
