#!/bin/bash
# =============================================================================
# ButtonLog Server Setup Script
# Run this ONCE on a fresh Ubuntu 22.04/24.04 server (Linode, AWS EC2, etc.)
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   error "This script must be run as root (use sudo)"
fi

# Configuration
APP_USER="buttonlog"
APP_DIR="/opt/buttonlog"
RELEASES_DIR="${APP_DIR}/releases"
CURRENT_LINK="${APP_DIR}/current"

log "Starting ButtonLog server setup..."

# =============================================================================
# 1. System Updates
# =============================================================================
log "Updating system packages..."
apt-get update && apt-get upgrade -y

# =============================================================================
# 2. Install Dependencies
# =============================================================================
log "Installing dependencies..."
apt-get install -y \
    curl \
    wget \
    git \
    unzip \
    build-essential \
    libncurses5-dev \
    libssl-dev \
    postgresql-client \
    nginx \
    certbot \
    python3-certbot-nginx \
    fail2ban \
    ufw

# =============================================================================
# 3. Install Erlang and Elixir (for running releases)
# =============================================================================
log "Installing Erlang/OTP..."
apt-get install -y erlang

# Note: For releases, we only need Erlang runtime, not Elixir
# The release is self-contained

# =============================================================================
# 4. Create Application User
# =============================================================================
log "Creating application user..."
if ! id -u ${APP_USER} >/dev/null 2>&1; then
    useradd -m -s /bin/bash ${APP_USER}
    log "Created user: ${APP_USER}"
else
    log "User ${APP_USER} already exists"
fi

# =============================================================================
# 5. Create Directory Structure
# =============================================================================
log "Creating directory structure..."
mkdir -p ${RELEASES_DIR}
mkdir -p ${APP_DIR}/config
mkdir -p ${APP_DIR}/logs
mkdir -p /var/log/buttonlog

chown -R ${APP_USER}:${APP_USER} ${APP_DIR}
chown -R ${APP_USER}:${APP_USER} /var/log/buttonlog

# =============================================================================
# 6. Create Environment File Template
# =============================================================================
log "Creating environment file template..."
cat > ${APP_DIR}/config/.env.template << 'EOF'
# ButtonLog Production Environment Configuration
# Copy this to .env and fill in your values

# Database (use Linode Managed PostgreSQL or AWS RDS)
DATABASE_URL=ecto://user:password@host:5432/buttonlog_prod

# Phoenix
SECRET_KEY_BASE=generate_with_mix_phx.gen.secret
PHX_HOST=your-domain.com
PORT=4000

# OAuth - Google
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=

# OAuth - Facebook (optional)
FACEBOOK_CLIENT_ID=
FACEBOOK_CLIENT_SECRET=

# OAuth - Apple (optional)
APPLE_CLIENT_ID=
APPLE_CLIENT_SECRET=

# Push Notifications - APNs (iOS)
APNS_KEY_ID=
APNS_TEAM_ID=
APNS_KEY_CONTENT=
APNS_BUNDLE_ID=com.buttonlog.app
APNS_ENVIRONMENT=production

# Push Notifications - FCM (Android)
FCM_PROJECT_ID=
FCM_SERVICE_ACCOUNT_JSON=

# Stripe
STRIPE_SECRET_KEY=
STRIPE_WEBHOOK_SECRET=
EOF

if [[ ! -f ${APP_DIR}/config/.env ]]; then
    cp ${APP_DIR}/config/.env.template ${APP_DIR}/config/.env
    chmod 600 ${APP_DIR}/config/.env
    chown ${APP_USER}:${APP_USER} ${APP_DIR}/config/.env
    warn "Created ${APP_DIR}/config/.env - EDIT THIS FILE with your values!"
fi

# =============================================================================
# 7. Create Systemd Service
# =============================================================================
log "Creating systemd service..."
cat > /etc/systemd/system/buttonlog.service << EOF
[Unit]
Description=ButtonLog Phoenix Application
After=network.target postgresql.service

[Service]
Type=simple
User=${APP_USER}
Group=${APP_USER}
WorkingDirectory=${CURRENT_LINK}
EnvironmentFile=${APP_DIR}/config/.env
ExecStart=${CURRENT_LINK}/bin/buttonlog start
ExecStop=${CURRENT_LINK}/bin/buttonlog stop
ExecReload=${CURRENT_LINK}/bin/buttonlog restart
Restart=on-failure
RestartSec=5
SyslogIdentifier=buttonlog
StandardOutput=append:/var/log/buttonlog/app.log
StandardError=append:/var/log/buttonlog/error.log

# Security hardening
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=${APP_DIR} /var/log/buttonlog
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
log "Systemd service created (not started yet - deploy first)"

# =============================================================================
# 8. Configure Nginx
# =============================================================================
log "Configuring Nginx..."
cat > /etc/nginx/sites-available/buttonlog << 'EOF'
upstream phoenix {
    server 127.0.0.1:4000;
}

server {
    listen 80;
    server_name YOUR_DOMAIN.com;  # CHANGE THIS

    # For Let's Encrypt verification
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    # Redirect all HTTP to HTTPS
    location / {
        return 301 https://$server_name$request_uri;
    }
}

server {
    listen 443 ssl http2;
    server_name YOUR_DOMAIN.com;  # CHANGE THIS

    # SSL certificates (will be created by certbot)
    ssl_certificate /etc/letsencrypt/live/YOUR_DOMAIN.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/YOUR_DOMAIN.com/privkey.pem;

    # SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 1d;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # Logging
    access_log /var/log/nginx/buttonlog_access.log;
    error_log /var/log/nginx/buttonlog_error.log;

    # WebSocket support for Phoenix LiveView
    location /live {
        proxy_pass http://phoenix;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 86400;
    }

    # WebSocket for Phoenix Channels
    location /socket {
        proxy_pass http://phoenix;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 86400;
    }

    # Static assets with caching
    location /assets {
        proxy_pass http://phoenix;
        proxy_set_header Host $host;
        proxy_cache_valid 200 1y;
        add_header Cache-Control "public, max-age=31536000, immutable";
    }

    # All other requests
    location / {
        proxy_pass http://phoenix;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# Enable the site
ln -sf /etc/nginx/sites-available/buttonlog /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

warn "Edit /etc/nginx/sites-available/buttonlog and replace YOUR_DOMAIN.com"

# =============================================================================
# 9. Configure Firewall
# =============================================================================
log "Configuring firewall..."
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 'Nginx Full'
ufw --force enable

# =============================================================================
# 10. Configure Log Rotation
# =============================================================================
log "Configuring log rotation..."
cat > /etc/logrotate.d/buttonlog << EOF
/var/log/buttonlog/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 ${APP_USER} ${APP_USER}
    sharedscripts
    postrotate
        systemctl reload buttonlog > /dev/null 2>&1 || true
    endscript
}
EOF

# =============================================================================
# Done!
# =============================================================================
log "=========================================="
log "Server setup complete!"
log "=========================================="
echo ""
echo "Next steps:"
echo "1. Edit ${APP_DIR}/config/.env with your configuration"
echo "2. Edit /etc/nginx/sites-available/buttonlog with your domain"
echo "3. Run: certbot --nginx -d your-domain.com"
echo "4. Deploy your first release using deploy.sh"
echo "5. Run: systemctl enable buttonlog"
echo ""
warn "Don't forget to configure your managed PostgreSQL!"
