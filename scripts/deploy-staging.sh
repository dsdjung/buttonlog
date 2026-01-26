#!/bin/bash

# ButtonLog Staging Deployment Script
# Deploys the latest code to the staging server

set -e

STAGING_HOST="deploy@45.33.107.135"
STAGING_DIR="/opt/buttonlog"
SOURCE_DIR="/opt/buttonlog-src"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  ButtonLog Staging Deployment${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check SSH connectivity
echo -e "${YELLOW}[1/7] Checking SSH connectivity...${NC}"
if ! ssh -o ConnectTimeout=5 $STAGING_HOST "echo 'Connected'" > /dev/null 2>&1; then
    echo -e "${RED}Error: Cannot connect to staging server${NC}"
    exit 1
fi
echo -e "${GREEN}✓ SSH connection OK${NC}"
echo ""

# Create deployment script
DEPLOY_SCRIPT=$(cat << 'ENDSCRIPT'
#!/bin/bash
set -e

# Load ASDF environment
export PATH="$HOME/.asdf/shims:$HOME/.asdf/bin:$PATH"
source $HOME/.asdf/asdf.sh 2>/dev/null || true

echo "[2/7] Checking installed versions..."
echo "  Elixir: $(elixir --version | head -1)"
echo "  Node: $(node --version)"
echo ""

echo "[3/7] Pulling latest code..."
cd /opt/buttonlog-src
git fetch origin
git reset --hard origin/master
echo "  Commit: $(git log -1 --oneline)"
echo ""

echo "[4/7] Building backend..."
cd backend
export MIX_ENV=prod

# Remove .tool-versions to use system versions
rm -f ../.tool-versions .tool-versions 2>/dev/null || true

echo "  Installing dependencies..."
mix deps.get --only prod > /dev/null 2>&1

echo "  Compiling..."
mix compile > /dev/null 2>&1

echo "  Building assets..."
cd assets
npm install --silent > /dev/null 2>&1
npm run deploy > /dev/null 2>&1
cd ..
mix phx.digest > /dev/null 2>&1
echo ""

echo "[5/7] Building release..."
mix release > /dev/null 2>&1
echo "  Release built in _build/prod/rel/buttonlog"
echo ""

echo "[6/7] Deploying release..."
# Stop service
sudo systemctl stop buttonlog || true

# Backup current deployment
if [ -d /opt/buttonlog ]; then
    BACKUP_NAME="buttonlog.bak.$(date +%Y%m%d%H%M%S)"
    sudo mv /opt/buttonlog /opt/$BACKUP_NAME
    echo "  Backed up to /opt/$BACKUP_NAME"
fi

# Copy new release
sudo cp -r _build/prod/rel/buttonlog /opt/buttonlog

# Restore env file
LATEST_BACKUP=$(ls -td /opt/buttonlog.bak.* 2>/dev/null | head -1)
if [ -n "$LATEST_BACKUP" ] && [ -f "$LATEST_BACKUP/.env" ]; then
    sudo cp "$LATEST_BACKUP/.env" /opt/buttonlog/.env
    echo "  Restored .env from backup"
fi
echo ""

echo "[7/7] Starting service..."
sudo systemctl start buttonlog
sleep 5

# Check status
if sudo systemctl is-active --quiet buttonlog; then
    echo "  Service is running!"
else
    echo "  ERROR: Service failed to start"
    sudo journalctl -u buttonlog --no-pager -n 20
    exit 1
fi
echo ""

echo "========================================="
echo "  Deployment Complete!"
echo "========================================="
ENDSCRIPT
)

# Run deployment
echo -e "${YELLOW}Starting deployment on staging server...${NC}"
echo ""
echo "$DEPLOY_SCRIPT" | ssh $STAGING_HOST 'bash -s'

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Deployment finished successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Test the API:"
echo "  curl https://staging.buttonlog.com/api/config"
echo ""
