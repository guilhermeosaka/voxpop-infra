# Cost Optimization Scripts

These scripts help reduce AWS costs by shutting down expensive resources during periods of inactivity.

## 💰 Estimated Savings

- **Idle mode**: ~80% cost reduction
- **Daily cost (active)**: ~$15-20/day
- **Daily cost (idle)**: ~$3-4/day (storage only)
- **Monthly savings**: ~$300-400 with 16 hours/day in idle mode

---

## 📁 Available Scripts

### Bash (Linux/Mac/WSL)
- `sleep.sh` - Shut down resources
- `wakeup.sh` - Start resources

### PowerShell (Windows)
- `sleep.ps1` - Shut down resources
- `wakeup.ps1` - Start resources

---

## 🚀 Usage

### Bash (Linux/Mac/WSL)

```bash
# Make scripts executable (first time only)
chmod +x scripts/*.sh

# Shut down resources
./scripts/sleep.sh

# Start resources
./scripts/wakeup.sh

# For production environment
./scripts/sleep.sh prod
./scripts/wakeup.sh prod
```

### PowerShell (Windows)

```powershell
# Shut down resources
.\scripts\sleep.ps1

# Start resources
.\scripts\wakeup.ps1

# For production environment
.\scripts\sleep.ps1 -Environment prod
.\scripts\wakeup.ps1 -Environment prod
```

---

## 🔧 Resource Management

### Sleep Mode (`sleep.sh` / `sleep.ps1`)
- ✅ ECS Identity Service → scaled to 0 tasks
- ✅ ECS Core Service → scaled to 0 tasks
- ✅ RDS Database → stopped (saves ~70% of RDS cost)
- ℹ️ ALB, VPC, and other infrastructure remains active (minimal cost)

### Wake Up Mode (`wakeup.sh` / `wakeup.ps1`)
- ✅ RDS Database → started and waits until available
- ✅ ECS Identity Service → scaled to 1 task
- ✅ ECS Core Service → scaled to 1 task
- ✅ Displays ALB URL and API endpoints

---

## ⏱️ Timing

**Shutdown:**
- ECS scales down: ~30 seconds
- RDS stops: ~2-3 minutes

**Startup:**
- RDS starts: ~2-3 minutes (script waits for availability)
- ECS scales up: ~1-2 minutes after RDS is ready
- **Total startup time: ~3-5 minutes**

---

## ⚠️ Important Notes

### RDS Auto-Start
AWS automatically restarts stopped RDS instances after **7 days**. Extended idle periods beyond one week will incur running database charges.

### Data Safety
- ✅ All data is **preserved** - no resources are deleted
- ✅ RDS is stopped, not destroyed
- ✅ ECS tasks scale to 0, configuration persists

### Terraform Compatibility
These scripts are **Terraform-safe**:
- ✅ Only modify runtime state (desired count, instance state)
- ✅ Do not alter infrastructure configuration
- ✅ Terraform will not attempt to revert these changes
- ✅ Safe to run `terraform apply` while in idle mode

---

## 🤖 Automation Options

### Option 1: Cron Job (Linux/Mac)
```bash
# Add to crontab for scheduled execution
0 23 * * * /path/to/voxpop.infra/scripts/sleep.sh
0 8 * * * /path/to/voxpop.infra/scripts/wakeup.sh
```

### Option 2: Task Scheduler (Windows)
Create scheduled tasks to execute PowerShell scripts at specified times.

### Option 3: AWS Lambda + EventBridge
Deploy Lambda functions triggered by EventBridge rules for cloud-native automation.

---

## 🐛 Troubleshooting

### "Service not found"
Verify the correct environment is specified. Default is `beta`.

### "Access denied"
Ensure AWS credentials are properly configured:
```bash
aws configure
```

### "Database is already stopped"
This is expected behavior. The script will skip the stop operation.

### Startup takes longer than expected
The script waits for RDS to reach an available state before scaling ECS services. This prevents connection errors.

---

## 💡 Best Practices

1. **Off-hours optimization**: Execute `sleep.sh` during non-working hours to reduce costs
2. **Extended downtime**: Run `sleep.sh` during weekends or vacations for maximum savings
3. **Status verification**: Use AWS Console to confirm resource states
4. **Scheduled reminders**: Set calendar alerts to start resources before they're needed

---

## 📊 Cost Analysis

### Continuous Operation (24/7)
- RDS db.t3.micro: ~$15/month
- ECS Fargate (2 services): ~$30/month
- ALB: ~$20/month
- **Total: ~$65/month**

### Optimized Schedule (16h/day idle)
- RDS (8h active + 16h idle): ~$7/month
- ECS (8h active): ~$10/month
- ALB (continuous): ~$20/month
- **Total: ~$37/month**
- **Savings: ~$28/month (43%)**

### Minimal Usage (2h/day active)
- RDS (2h active + 22h idle): ~$3/month
- ECS (2h active): ~$3/month
- ALB (continuous): ~$20/month
- **Total: ~$26/month**
- **Savings: ~$39/month (60%)**

---

## 🎯 Summary

**Standard workflow:**
```bash
# Shut down resources during idle periods
./scripts/sleep.sh

# Start resources when needed
./scripts/wakeup.sh
```

Optimize your AWS costs by managing resource availability based on actual usage patterns.
