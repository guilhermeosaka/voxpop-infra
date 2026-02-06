# Multi-Repository GitHub OIDC Setup

## What Changed

Your IAM role now supports **multiple GitHub repositories** using the same OIDC role for AWS access.

### Before (Single Repo)
```hcl
variable "github_repo" {
  type    = string
  default = "voxpop"
}

# Trust policy allowed only: repo:guilhermeosaka/voxpop:*
```

### After (Multiple Repos)
```hcl
variable "github_repos" {
  type    = list(string)
  default = ["voxpop", "voxpop-infra"]
}

# Trust policy now allows:
# - repo:guilhermeosaka/voxpop:*
# - repo:guilhermeosaka/voxpop-infra:*
```

---

## How It Works

The IAM role trust policy now uses a **dynamic list** to allow multiple repositories:

```hcl
StringLike = {
  "token.actions.githubusercontent.com:sub" = [
    for repo in var.github_repos : "repo:${var.github_org}/${repo}:*"
  ]
}
```

This generates:
```json
{
  "StringLike": {
    "token.actions.githubusercontent.com:sub": [
      "repo:guilhermeosaka/voxpop:*",
      "repo:guilhermeosaka/voxpop-infra:*"
    ]
  }
}
```

---

## Adding More Repositories

### Option 1: Update terraform.tfvars (Recommended)
```hcl
# In envs/beta/terraform.tfvars
github_repos = ["voxpop", "voxpop-infra", "voxpop-frontend", "another-repo"]
```

### Option 2: Update Default in variables.tf
```hcl
# In modules/iam/variables.tf
variable "github_repos" {
  type    = list(string)
  default = ["voxpop", "voxpop-infra", "new-repo"]
}
```

Then run:
```bash
terraform apply
```

---

## Testing the Fix

After applying the changes, your GitHub Actions workflow should work from **both repositories**:

1. **From voxpop-infra repo** (current PR):
   ```yaml
   - uses: aws-actions/configure-aws-credentials@v4
     with:
       role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
       aws-region: us-east-1
   ```

2. **From voxpop repo** (future):
   Same configuration works!

---

## Next Steps

1. **Apply the changes**:
   ```bash
   cd envs/beta
   terraform apply
   ```

2. **Get the role ARN**:
   ```bash
   terraform output github_actions_role_arn
   ```

3. **Add to GitHub Secrets** (in BOTH repos):
   - Go to repo Settings → Secrets and variables → Actions
   - Add secret: `AWS_ROLE_ARN` = `arn:aws:iam::303155796105:role/voxpop-beta-github-actions-role`

4. **Test the workflow**:
   - Push changes to your PR
   - GitHub Actions should now successfully assume the role

---

## Security Note

The trust policy uses wildcards (`repo:org/repo:*`) which allows:
- ✅ All branches
- ✅ All pull requests  
- ✅ All tags
- ✅ All environments

To restrict to specific branches:
```hcl
"token.actions.githubusercontent.com:sub" = [
  "repo:guilhermeosaka/voxpop:ref:refs/heads/main",
  "repo:guilhermeosaka/voxpop-infra:ref:refs/heads/main"
]
```

---

## Summary

✅ **Fixed**: OIDC role now supports multiple repos  
✅ **Current repos**: `voxpop`, `voxpop-infra`  
✅ **Easy to extend**: Just add to the list  
✅ **No separate roles needed**: One role for all your repos  

Your GitHub Actions workflows from **any configured repository** can now deploy to AWS! 🚀
