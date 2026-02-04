#!/bin/bash
# Sleep Mode - Turn off expensive AWS resources to save costs
# Usage: ./scripts/sleep.sh [environment]

set -e  # Exit on error

ENVIRONMENT=${1:-beta}
CLUSTER_NAME="voxpop-${ENVIRONMENT}"
DB_INSTANCE="voxpop-${ENVIRONMENT}-postgres"
REGION="us-east-1"

echo "🌙 Entering Sleep Mode for ${ENVIRONMENT} environment..."
echo "================================================"

# Scale ECS services to 0
echo ""
echo "📉 Scaling down ECS services..."
aws ecs update-service \
  --cluster "$CLUSTER_NAME" \
  --service "voxpop-identity-${ENVIRONMENT}" \
  --desired-count 0 \
  --region "$REGION" \
  --no-cli-pager \
  --output text > /dev/null

echo "✅ Identity service scaled to 0"

aws ecs update-service \
  --cluster "$CLUSTER_NAME" \
  --service "voxpop-core-${ENVIRONMENT}" \
  --desired-count 0 \
  --region "$REGION" \
  --no-cli-pager \
  --output text > /dev/null

echo "✅ Core service scaled to 0"

# Stop RDS instance
echo ""
echo "🛑 Stopping RDS database..."
aws rds stop-db-instance \
  --db-instance-identifier "$DB_INSTANCE" \
  --region "$REGION" \
  --no-cli-pager \
  --output text > /dev/null

echo "✅ RDS database stopping (will take a few minutes)"

# Summary
echo ""
echo "================================================"
echo "💤 Sleep mode activated!"
echo ""
echo "Resources turned off:"
echo "  - ECS Identity Service (scaled to 0)"
echo "  - ECS Core Service (scaled to 0)"
echo "  - RDS Database (stopping)"
echo ""
echo "💰 Estimated savings: ~80% of daily cost"
echo ""
echo "⏰ To wake up: ./scripts/wakeup.sh"
echo "================================================"
