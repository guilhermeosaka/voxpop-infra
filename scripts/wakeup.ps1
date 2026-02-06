# Wake Up Mode - Turn on AWS resources
# Usage: .\scripts\wakeup.ps1 [-Environment beta]

param(
    [string]$Environment = "beta"
)

$ErrorActionPreference = "Stop"

$ClusterName = "voxpop-$Environment"
$DbInstance = "voxpop-$Environment-postgres"
$Region = "us-east-1"

Write-Host "☀️  Waking up $Environment environment..." -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

# Start RDS instance
Write-Host ""
Write-Host "🚀 Starting RDS database..." -ForegroundColor Yellow

aws rds start-db-instance `
  --db-instance-identifier $DbInstance `
  --region $Region `
  --no-cli-pager `
  --output text | Out-Null

Write-Host "✅ RDS database starting (will take 2-3 minutes)" -ForegroundColor Green

# Wait for RDS to be available
Write-Host ""
Write-Host "⏳ Waiting for database to be available..." -ForegroundColor Yellow

aws rds wait db-instance-available `
  --db-instance-identifier $DbInstance `
  --region $Region

Write-Host "✅ Database is now available" -ForegroundColor Green

# Scale ECS services back to 1
Write-Host ""
Write-Host "📈 Scaling up ECS services..." -ForegroundColor Yellow

aws ecs update-service `
  --cluster $ClusterName `
  --service "voxpop-identity-$Environment" `
  --desired-count 1 `
  --region $Region `
  --no-cli-pager `
  --output text | Out-Null

Write-Host "✅ Identity service scaled to 1" -ForegroundColor Green

aws ecs update-service `
  --cluster $ClusterName `
  --service "voxpop-core-$Environment" `
  --desired-count 1 `
  --region $Region `
  --no-cli-pager `
  --output text | Out-Null

Write-Host "✅ Core service scaled to 1" -ForegroundColor Green

# Get ALB URL
Write-Host ""
Write-Host "🔍 Getting ALB URL..." -ForegroundColor Yellow

$AlbUrl = aws elbv2 describe-load-balancers `
  --region $Region `
  --query "LoadBalancers[?contains(LoadBalancerName, 'voxpop-$Environment')].DNSName" `
  --output text

# Summary
Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "✨ Wake up complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Resources turned on:"
Write-Host "  - RDS Database (running)"
Write-Host "  - ECS Identity Service (1 task)"
Write-Host "  - ECS Core Service (1 task)"
Write-Host ""
Write-Host "🌐 Your application will be available at:" -ForegroundColor Yellow
Write-Host "   http://$AlbUrl"
Write-Host ""
Write-Host "API Endpoints:"
Write-Host "   Identity: http://$AlbUrl/identity"
Write-Host "   Core:     http://$AlbUrl/core"
Write-Host ""
Write-Host "⏱️  Services may take 1-2 minutes to fully start" -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor Cyan
