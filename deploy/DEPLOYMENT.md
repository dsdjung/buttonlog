# ButtonLog Deployment Guide

This guide covers deploying ButtonLog to production on Linode (or similar VPS).

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Initial Server Setup](#initial-server-setup)
3. [Database Setup](#database-setup)
4. [Environment Configuration](#environment-configuration)
5. [First Deployment](#first-deployment)
6. [Subsequent Deployments](#subsequent-deployments)
7. [Rollback](#rollback)
8. [Monitoring](#monitoring)
9. [CI/CD with GitHub Actions](#cicd-with-github-actions)
10. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Local Machine
- Git
- Elixir 1.18+
- Node.js 20+
- SSH key configured

### Server (Linode/VPS)
- Ubuntu 22.04 or 24.04
- Minimum 4GB RAM (2GB for small deployments)
- SSH access

### Services
- Linode Managed PostgreSQL (recommended) or self-hosted
- Domain name with DNS configured
- SSL certificate (via Let's Encrypt)

---

## Initial Server Setup

### 1. Create a Linode

1. Log into Linode Cloud Manager
2. Create a new Linode:
   - **Image**: Ubuntu 24.04 LTS
   - **Region**: Choose closest to your users
   - **Plan**: Dedicated 4GB ($36/mo) for production
   - **Label**: buttonlog-prod

### 2. Run Server Setup Script

```bash
# SSH into your new server
ssh root@your-server-ip

# Download and run setup script
curl -sSL https://raw.githubusercontent.com/YOUR_REPO/buttonlog/master/deploy/scripts/setup-server.sh | bash
```

Or manually:

```bash
# Clone repo and run setup
git clone https://github.com/YOUR_REPO/buttonlog.git /tmp/buttonlog
chmod +x /tmp/buttonlog/deploy/scripts/setup-server.sh
/tmp/buttonlog/deploy/scripts/setup-server.sh
rm -rf /tmp/buttonlog
```

### 3. Configure Your Domain

1. Point your domain's A record to your server's IP
2. Edit nginx config:
   ```bash
   sudo nano /etc/nginx/sites-available/buttonlog
   # Replace YOUR_DOMAIN.com with your actual domain
   ```

### 4. Get SSL Certificate

```bash
sudo certbot --nginx -d your-domain.com
```

---

## Database Setup

### Option A: Linode Managed PostgreSQL (Recommended)

1. Create a Managed Database in Linode:
   - **Engine**: PostgreSQL 16
   - **Region**: Same as your Linode
   - **Plan**: Shared 1GB ($15/mo) to start

2. Get connection string from Linode dashboard

3. Allow your Linode's IP in the database's access controls

### Option B: Self-Hosted PostgreSQL

```bash
sudo apt install postgresql postgresql-contrib
sudo -u postgres createuser -P buttonlog
sudo -u postgres createdb -O buttonlog buttonlog_prod
```

---

## Environment Configuration

Edit the environment file:

```bash
sudo nano /opt/buttonlog/config/.env
```

Required variables:

```bash
# Database
DATABASE_URL=ecto://user:password@host:5432/buttonlog_prod

# Phoenix (generate with: mix phx.gen.secret)
SECRET_KEY_BASE=your-64-char-secret-key-here
PHX_HOST=your-domain.com
PORT=4000

# OAuth - At least Google is recommended
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret

# Push Notifications (see IOS_PUSH_NOTIFICATIONS.md)
APNS_KEY_ID=your-key-id
APNS_TEAM_ID=your-team-id
APNS_KEY_CONTENT="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----"
APNS_ENVIRONMENT=production

# Stripe (if using subscriptions)
STRIPE_SECRET_KEY=sk_live_...
STRIPE_WEBHOOK_SECRET=whsec_...
```

---

## First Deployment

### From Your Local Machine

1. Configure deployment target:

```bash
export DEPLOY_HOST=your-domain.com
export DEPLOY_PORT=22  # if using non-standard SSH port
```

2. Run deployment:

```bash
cd /path/to/buttonlog
chmod +x deploy/scripts/*.sh
./deploy/scripts/deploy.sh
```

3. Enable the service:

```bash
ssh buttonlog@your-domain.com "sudo systemctl enable buttonlog"
```

4. Verify:

```bash
curl https://your-domain.com/health
```

---

## Subsequent Deployments

### Manual Deployment

```bash
# Deploy latest code
./deploy/scripts/deploy.sh

# Or deploy specific version/tag
./deploy/scripts/deploy.sh v1.2.3
```

### Using GitHub Actions

1. Set up repository secrets:
   - `DEPLOY_SSH_KEY`: Private SSH key for buttonlog user

2. Set up repository variables:
   - `DEPLOY_HOST`: your-domain.com
   - `DEPLOY_USER`: buttonlog
   - `DEPLOY_PORT`: 22

3. Trigger deployment:
   - Go to Actions → Deploy to Production → Run workflow

---

## Rollback

### Quick Rollback to Previous Version

```bash
./deploy/scripts/rollback.sh previous
```

### Rollback to Specific Version

```bash
# List available releases
./deploy/scripts/rollback.sh list

# Rollback to specific release
./deploy/scripts/rollback.sh buttonlog-v1.2.0
```

---

## Monitoring

### View Logs

```bash
# Live application logs
./deploy/scripts/remote-commands.sh logs

# Error logs only
./deploy/scripts/remote-commands.sh logs-error
```

### Check Status

```bash
./deploy/scripts/remote-commands.sh status
./deploy/scripts/remote-commands.sh health
```

### Remote Console (IEx)

```bash
./deploy/scripts/remote-commands.sh console
```

### System Resources

```bash
./deploy/scripts/remote-commands.sh disk
./deploy/scripts/remote-commands.sh memory
```

---

## CI/CD with GitHub Actions

### Automatic Testing

Every push triggers:
1. Code formatting check
2. Compilation with warnings-as-errors
3. Full test suite

### Manual Production Deployment

1. Go to GitHub → Actions → "Deploy to Production"
2. Click "Run workflow"
3. Optionally specify a version tag
4. Monitor the deployment progress

### Required GitHub Setup

**Secrets** (Settings → Secrets → Actions):
- `DEPLOY_SSH_KEY`: SSH private key

**Variables** (Settings → Variables → Actions):
- `DEPLOY_HOST`: your-domain.com
- `DEPLOY_USER`: buttonlog
- `DEPLOY_PORT`: 22 (optional)

**Environment** (Settings → Environments → production):
- Add required reviewers for deployment approval
- Add deployment branch rules

---

## Troubleshooting

### Service Won't Start

```bash
# Check service status
sudo systemctl status buttonlog

# View recent logs
sudo journalctl -u buttonlog -n 100

# Check for port conflicts
sudo lsof -i :4000
```

### Database Connection Issues

```bash
# Test database connectivity
source /opt/buttonlog/config/.env
psql $DATABASE_URL -c "SELECT 1"

# Check database URL format
echo $DATABASE_URL
```

### SSL Certificate Issues

```bash
# Test certificate
sudo certbot certificates

# Renew if needed
sudo certbot renew

# Check nginx config
sudo nginx -t
```

### Migration Failed

```bash
# Run migrations manually
./deploy/scripts/remote-commands.sh migrate

# Or via console
./deploy/scripts/remote-commands.sh console
# Then: ButtonLog.Release.migrate()
```

### Out of Memory

```bash
# Check memory
./deploy/scripts/remote-commands.sh memory

# Consider upgrading Linode plan
# Or reduce BEAM schedulers in vm.args
```

---

## Backup & Recovery

### Database Backup

```bash
# Download backup locally
./deploy/scripts/remote-commands.sh db-backup
```

### Restore from Backup

```bash
# On server
source /opt/buttonlog/config/.env
gunzip buttonlog_backup_YYYYMMDD.sql.gz
psql $DATABASE_URL < buttonlog_backup_YYYYMMDD.sql
```

---

## Security Checklist

- [ ] SSH key-only authentication (disable password)
- [ ] Firewall enabled (UFW)
- [ ] fail2ban installed and configured
- [ ] SSL certificate installed
- [ ] Environment file permissions set (600)
- [ ] Database credentials not in version control
- [ ] Regular security updates (`apt update && apt upgrade`)

---

## Cost Summary (Linode)

| Component | Plan | Monthly Cost |
|-----------|------|--------------|
| App Server | Dedicated 4GB | $36 |
| Database | Managed PostgreSQL 1GB | $15 |
| Backups | 20% of Linode cost | ~$7 |
| **Total** | | **~$58/mo** |

For smaller deployments, you can start with:
- Shared 2GB Linode ($12/mo)
- Self-hosted PostgreSQL (included)
- **Total: ~$12/mo**
