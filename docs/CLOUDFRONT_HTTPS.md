# CloudFront Free HTTPS Setup

This guide shows you how to enable **free HTTPS** using AWS CloudFront without buying a domain.

---

## What You Get

✅ **Free HTTPS URL**: `https://d1234abcd.cloudfront.net`  
✅ **No domain required**: Works immediately  
✅ **CDN benefits**: Faster global access  
✅ **DDoS protection**: Built-in AWS Shield  
✅ **Zero cost**: Free tier covers most beta usage  

---

## How It Works

```
User → HTTPS (CloudFront) → HTTP (ALB) → ECS Services
       ✅ Encrypted           ✅ Internal
```

CloudFront provides the HTTPS layer, then forwards to your HTTP ALB internally.

---

## Setup (Already Done!)

The CloudFront module is already configured in your infrastructure:

```hcl
# envs/beta/main.tf
module "cloudfront" {
  source = "../../modules/cloudfront"

  environment  = var.environment
  alb_dns_name = module.alb.alb_dns_name
  
  # API-friendly settings (no caching)
  default_ttl = 0
  max_ttl     = 0
}
```

---

## Deploy CloudFront

```bash
cd envs/beta

# Initialize new module
terraform init

# Plan (should show CloudFront distribution creation)
terraform plan

# Apply (takes ~5-10 minutes to deploy)
terraform apply
```

**Deployment time**: ~5-10 minutes (CloudFront is slow to deploy)

---

## Get Your HTTPS URL

After deployment:

```bash
# Get CloudFront URL
terraform output cloudfront_url

# Example output:
# https://d1a2b3c4d5e6f7.cloudfront.net
```

---

## Test Your HTTPS Endpoints

```bash
# Get all HTTPS endpoints
terraform output https_api_endpoints

# Test identity service
curl https://d1a2b3c4d5e6f7.cloudfront.net/identity

# Test core service  
curl https://d1a2b3c4d5e6f7.cloudfront.net/core
```

---

## Update Your Frontend

Replace HTTP URLs with HTTPS CloudFront URLs:

**Before:**
```javascript
const API_URL = 'http://voxpop-beta-alb-xxx.us-east-1.elb.amazonaws.com';
```

**After:**
```javascript
const API_URL = 'https://d1a2b3c4d5e6f7.cloudfront.net';
```

---

## Configuration Details

### Caching Behavior

**API paths** (`/identity/*`, `/core/*`):
- ✅ No caching (TTL = 0)
- ✅ All headers forwarded
- ✅ Cookies forwarded
- ✅ Query strings forwarded

**Perfect for APIs!**

### Security

- ✅ **Automatic HTTP → HTTPS redirect**
- ✅ **TLS 1.2+ only**
- ✅ **HTTP/2 and HTTP/3 enabled**
- ✅ **Compression enabled**

### Geographic Distribution

**Price Class 100** (cheapest):
- ✅ United States
- ✅ Canada
- ✅ Europe

**To expand globally**, change in `main.tf`:
```hcl
price_class = "PriceClass_All"  # Worldwide
```

---

## Cost Estimate

### Free Tier (First 12 Months)
- ✅ 1 TB data transfer out: FREE
- ✅ 10M HTTP/HTTPS requests: FREE
- ✅ 2M CloudFront function invocations: FREE

### After Free Tier (Beta Usage)
- ~1000 requests/day = **~$0.01/month**
- ~10GB transfer/month = **~$0.85/month**
- **Total: ~$1/month** (very cheap!)

### Production Usage
- 1M requests/month = **~$1/month**
- 100GB transfer = **~$8.50/month**

**Much cheaper than buying a domain + SSL!**

---

## Advantages vs Custom Domain

| Feature | CloudFront (Free) | Custom Domain |
|---------|-------------------|---------------|
| Cost | FREE | ~$10/year |
| Setup Time | 10 minutes | 30-60 minutes |
| HTTPS | ✅ Free | ✅ Free (ACM) |
| URL | `d123.cloudfront.net` | `api.yourdomain.com` |
| Professional | ⚠️ Less | ✅ More |
| CDN | ✅ Included | ❌ Extra cost |

---

## Limitations

⚠️ **Ugly URL**: `d1a2b3c4d5e6f7.cloudfront.net` (not memorable)  
⚠️ **Can't customize**: Stuck with CloudFront domain  
⚠️ **Slower updates**: ~5-10 min to deploy changes  

**For production**, consider getting a custom domain later.

---

## Troubleshooting

### "502 Bad Gateway"
- Check ALB is running: `terraform output alb_url`
- Verify ECS tasks are healthy
- Wait a few minutes after deployment

### "CloudFront still deploying"
- Deployment takes 5-10 minutes
- Check status: `aws cloudfront get-distribution --id <id>`
- Wait for `Status: Deployed`

### "Mixed content" errors
- Make sure you're using `https://` not `http://`
- Update all API calls in frontend

---

## Monitoring

### Check CloudFront Status
```bash
# Get distribution ID
terraform output cloudfront_id

# Check status
aws cloudfront get-distribution --id E1234567890ABC
```

### View Metrics
```bash
# CloudWatch metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/CloudFront \
  --metric-name Requests \
  --dimensions Name=DistributionId,Value=E1234567890ABC \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-02T00:00:00Z \
  --period 3600 \
  --statistics Sum
```

---

## Invalidating Cache (If Needed)

If you need to clear CloudFront cache:

```bash
# Invalidate all
aws cloudfront create-invalidation \
  --distribution-id E1234567890ABC \
  --paths "/*"

# Invalidate specific path
aws cloudfront create-invalidation \
  --distribution-id E1234567890ABC \
  --paths "/identity/*"
```

**Note**: First 1000 invalidations/month are free!

---

## Upgrading to Custom Domain Later

When you're ready to get a custom domain:

1. **Buy domain** (~$10/year)
2. **Request ACM certificate**
3. **Update CloudFront**:
   ```hcl
   # In modules/cloudfront/main.tf
   aliases = ["api.yourdomain.com"]
   
   viewer_certificate {
     acm_certificate_arn = "arn:aws:acm:..."
     ssl_support_method  = "sni-only"
   }
   ```
4. **Point domain to CloudFront**
5. **Apply**: `terraform apply`

---

## Summary

**Quick commands:**
```bash
# Deploy CloudFront
cd envs/beta
terraform init
terraform apply

# Get HTTPS URL
terraform output cloudfront_url

# Test
curl $(terraform output -raw cloudfront_url)/identity
```

**You now have free HTTPS!** 🎉🔒

Use the CloudFront URL in your frontend and enjoy secure, encrypted API calls without spending a penny on domains or certificates.
