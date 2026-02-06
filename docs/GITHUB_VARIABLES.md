# Terraform Variables for GitHub Actions (Beta Environment)
# Add these as GitHub Repository Variables (not secrets, except passwords)

## How to Add Variables

Go to: **Repo Settings → Secrets and variables → Actions → Variables tab**

### Repository Variables (Non-Sensitive)

```
TF_VAR_aws_region = us-east-1
TF_VAR_environment = beta
TF_VAR_vpc_cidr = 10.0.0.0/16
TF_VAR_availability_zone_count = 2
TF_VAR_enable_vpc_flow_logs = false
TF_VAR_allowed_cidr_blocks = ["0.0.0.0/0"]

TF_VAR_github_org = guilhermeosaka
TF_VAR_github_repos = ["voxpop-services", "voxpop-infra", "voxpop-web"]

TF_VAR_db_name = voxpop
TF_VAR_db_username = voxpop_admin

TF_VAR_identity_container_image = nginx:latest
TF_VAR_identity_container_port = 80
TF_VAR_identity_cpu = 256
TF_VAR_identity_memory = 512

TF_VAR_core_container_image = nginx:latest
TF_VAR_core_container_port = 80
TF_VAR_core_cpu = 256
TF_VAR_core_memory = 512

TF_VAR_alb_certificate_arn = ""
```

### Environment Secrets (Sensitive - use Secrets tab)

In the **beta** environment:
```
TF_VAR_DB_PASSWORD = "[PASSWORD]"

AWS_ROLE_ARN = arn:aws:iam::303155796105:role/voxpop-beta-github-actions-role
```

---

## Alternative: Use terraform.tfvars in Repo

**Simpler approach**: Create a `terraform.tfvars` file specifically for CI/CD:

### Create: `envs/beta/terraform.auto.tfvars`

```hcl
# Auto-loaded by Terraform
# Safe to commit (no secrets!)

aws_region  = "us-east-1"
environment = "beta"

vpc_cidr                = "10.0.0.0/16"
availability_zone_count = 2
enable_vpc_flow_logs    = false
allowed_cidr_blocks     = ["0.0.0.0/0"]

github_org   = "guilhermeosaka"
github_repos = ["voxpop-services", "voxpop-infra", "voxpop-web"]

db_name     = "voxpop"
db_username = "voxpop_admin"
# db_password from secret



identity_container_image = "nginx:latest"
identity_container_port  = 80
identity_cpu             = 256
identity_memory          = 512

core_container_image = "nginx:latest"
core_container_port  = 80
core_cpu             = 256
core_memory          = 512

alb_certificate_arn = ""
```

This file:
- ✅ Can be committed to Git (no secrets)
- ✅ Auto-loaded by Terraform
- ✅ Works in both local and CI/CD
- ✅ Only secrets come from GitHub Secrets

---

## Recommended Approach

**Use `terraform.auto.tfvars`** - it's much simpler!

1. Create the file above
2. Commit it to Git
3. Only keep passwords in GitHub Secrets
4. Workflows work automatically

This way you don't need to add 20+ variables to GitHub!
