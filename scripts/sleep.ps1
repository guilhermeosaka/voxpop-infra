# Sleep Mode - Turn off expensive AWS resources to save costs
# Usage: .\scripts\sleep.ps1 [-Environment beta]

param(
    [string]$Environment = "beta"
)

$ErrorActionPreference = "Stop"

$ClusterName = "voxpop-$Environment"
$DbInstance = "voxpop-$Environment-postgres"
$Region = "us-east-1"

Write-Host "🌙 Entering Sleep Mode for $Environment environment..." -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

# Scale ECS services to 0
Write-Host ""
Write-Host "📉 Scaling down ECS services..." -ForegroundColor Yellow

aws ecs update-service `
  --cluster $ClusterName `
  --service "voxpop-identity-$Environment" `
  --desired-count 0 `
  --region $Region `
  --no-cli-pager `
  --output text | Out-Null

Write-Host "✅ Identity service scaled to 0" -ForegroundColor Green

aws ecs update-service `
  --cluster $ClusterName `
  --service "voxpop-core-$Environment" `
  --desired-count 0 `
  --region $Region `
  --no-cli-pager `
  --output text | Out-Null

Write-Host "✅ Core service scaled to 0" -ForegroundColor Green

# Stop RDS instance
Write-Host ""
Write-Host "🛑 Stopping RDS database..." -ForegroundColor Yellow

aws rds stop-db-instance `
  --db-instance-identifier $DbInstance `
  --region $Region `
  --no-cli-pager `
  --output text | Out-Null

Write-Host "✅ RDS database stopping (will take a few minutes)" -ForegroundColor Green

# Summary
Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "💤 Sleep mode activated!" -ForegroundColor Green
Write-Host ""
Write-Host "Resources turned off:"
Write-Host "  - ECS Identity Service (scaled to 0)"
Write-Host "  - ECS Core Service (scaled to 0)"
Write-Host "  - RDS Database (stopping)"
Write-Host ""
Write-Host "💰 Estimated savings: ~80% of daily cost" -ForegroundColor Yellow
Write-Host ""
Write-Host "⏰ To wake up: .\scripts\wakeup.ps1" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
