#!/bin/bash
# Wake Up Mode - Turn on AWS resources
# Usage: ./scripts/wakeup.sh [environment]

set -e  # Exit on error

ENVIRONMENT=${1:-beta}
CLUSTER_NAME="voxpop-${ENVIRONMENT}"
DB_INSTANCE="voxpop-${ENVIRONMENT}-postgres"
REGION="us-east-1"

echo "☀️  Waking up ${ENVIRONMENT} environment..."
echo "================================================"

# Start RDS instance
echo ""
echo "🚀 Starting RDS database..."
aws rds start-db-instance \
  --db-instance-identifier "$DB_INSTANCE" \
  --region "$REGION" \
  --no-cli-pager \
  --output text > /dev/null

echo "✅ RDS database starting (will take 2-3 minutes)"

# Wait for RDS to be available
echo ""
echo "⏳ Waiting for database to be available..."
aws rds wait db-instance-available \
  --db-instance-identifier "$DB_INSTANCE" \
  --region "$REGION"

echo "✅ Database is now available"

# Scale ECS services back to 1
echo ""
echo "📈 Scaling up ECS services..."
aws ecs update-service \
  --cluster "$CLUSTER_NAME" \
  --service "voxpop-identity-${ENVIRONMENT}" \
  --desired-count 1 \
  --region "$REGION" \
  --no-cli-pager \
  --output text > /dev/null

echo "✅ Identity service scaled to 1"

aws ecs update-service \
  --cluster "$CLUSTER_NAME" \
  --service "voxpop-core-${ENVIRONMENT}" \
  --desired-count 1 \
  --region "$REGION" \
  --no-cli-pager \
  --output text > /dev/null

echo "✅ Core service scaled to 1"

# Get ALB URL
echo ""
echo "🔍 Getting ALB URL..."
ALB_URL=$(aws elbv2 describe-load-balancers \
  --region "$REGION" \
  --query "LoadBalancers[?contains(LoadBalancerName, 'voxpop-${ENVIRONMENT}')].DNSName" \
  --output text)

# Summary
echo ""
echo "================================================"
echo "✨ Wake up complete!"
echo ""
echo "Resources turned on:"
echo "  - RDS Database (running)"
echo "  - ECS Identity Service (1 task)"
echo "  - ECS Core Service (1 task)"
echo ""
echo "🌐 Your application will be available at:"
echo "   http://${ALB_URL}"
echo ""
echo "API Endpoints:"
echo "   Identity: http://${ALB_URL}/identity"
echo "   Core:     http://${ALB_URL}/core"
echo ""
echo "⏱️  Services may take 1-2 minutes to fully start"
echo "================================================"
