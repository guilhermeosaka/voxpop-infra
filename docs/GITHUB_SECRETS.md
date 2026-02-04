# GitHub Actions Secrets Setup

## Required Secrets

Add these secrets to your GitHub repository for CI/CD to work:

### 1. AWS OIDC Role ARN
**Name**: `AWS_ROLE_ARN`  
**Value**: Get from Terraform output:
```bash
cd envs/beta
terraform output github_actions_role_arn
```
Example: `arn:aws:iam::303155796105:role/voxpop-beta-github-actions-role`

### 2. Database Password
**Name**: `TF_VAR_DB_PASSWORD`  
**Value**: Your RDS database password (same as in `terraform.tfvars`)  
Example: `MySecretPassword123!`

### 3. RabbitMQ Password (Optional)
**Name**: `TF_VAR_RABBITMQ_PASSWORD`  
**Value**: Your RabbitMQ password (only needed if `enable_rabbitmq = true`)  
Example: `MySecretPassword123!`

---

## How to Add Secrets

1. Go to your GitHub repository
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add each secret with the name and value above

---

## How It Works

GitHub Actions workflows use these secrets as environment variables:

```yaml
- name: Terraform Plan
  env:
    TF_VAR_db_password: ${{ secrets.TF_VAR_DB_PASSWORD }}
    TF_VAR_rabbitmq_password: ${{ secrets.TF_VAR_RABBITMQ_PASSWORD }}
  run: terraform plan
```

Terraform automatically picks up `TF_VAR_*` environment variables and uses them as variable values.

---

## Security Best Practices

✅ **Never commit** `terraform.tfvars` with passwords  
✅ **Use GitHub Secrets** for all sensitive values  
✅ **Rotate passwords** regularly  
✅ **Use AWS Secrets Manager** for production (future improvement)  

---

## Quick Setup Commands

```bash
# 1. Get the role ARN
cd envs/beta
terraform output github_actions_role_arn

# 2. Add secrets to GitHub (via UI)
# - AWS_ROLE_ARN: <output from above>
# - TF_VAR_DB_PASSWORD: <your db password>
# - TF_VAR_RABBITMQ_PASSWORD: <your rabbitmq password> (optional)

# 3. Push changes to trigger workflow
git push
```

Your GitHub Actions should now work! 🎉
