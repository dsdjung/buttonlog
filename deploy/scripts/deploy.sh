#!/bin/bash
# =============================================================================
# ButtonLog Deployment Script
# Run from your LOCAL machine to deploy to production
# =============================================================================

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
step() { echo -e "${BLUE}[STEP]${NC} $1"; }

# =============================================================================
# Configuration - EDIT THESE
# =============================================================================
SERVER_USER="buttonlog"
SERVER_HOST="${DEPLOY_HOST:-your-server.com}"  # Set DEPLOY_HOST env var or edit here
SERVER_PORT="${DEPLOY_PORT:-22}"
APP_DIR="/opt/buttonlog"
RELEASES_DIR="${APP_DIR}/releases"
CURRENT_LINK="${APP_DIR}/current"

# Get version from git or argument
VERSION="${1:-$(git describe --tags --always 2>/dev/null || date +%Y%m%d%H%M%S)}"
RELEASE_NAME="buttonlog-${VERSION}"
RELEASE_DIR="${RELEASES_DIR}/${RELEASE_NAME}"

# =============================================================================
# Pre-flight Checks
# =============================================================================
step "Running pre-flight checks..."

# Check if we're in the right directory
if [[ ! -f "backend/mix.exs" ]]; then
    error "Run this script from the buttonlog repository root"
fi

# Check SSH connection
if ! ssh -q -o BatchMode=yes -o ConnectTimeout=5 -p ${SERVER_PORT} ${SERVER_USER}@${SERVER_HOST} exit; then
    error "Cannot connect to ${SERVER_HOST}. Check your SSH configuration."
fi

log "Deploying version: ${VERSION}"
log "Target: ${SERVER_USER}@${SERVER_HOST}"

# =============================================================================
# Step 1: Run Tests Locally
# =============================================================================
step "Running tests..."
cd backend
if ! (source .env 2>/dev/null; mix test); then
    error "Tests failed! Fix them before deploying."
fi
cd ..

# =============================================================================
# Step 2: Build Release
# =============================================================================
step "Building release..."
cd backend

# Clean previous builds
rm -rf _build/prod

# Get dependencies
MIX_ENV=prod mix deps.get --only prod

# Compile assets
cd assets
npm ci
npm run deploy
cd ..

# Digest assets
MIX_ENV=prod mix phx.digest

# Compile
MIX_ENV=prod mix compile

# Build release
MIX_ENV=prod mix release

cd ..

log "Release built successfully"

# =============================================================================
# Step 3: Create Release Tarball
# =============================================================================
step "Creating release tarball..."
TARBALL="/tmp/${RELEASE_NAME}.tar.gz"
tar -czf ${TARBALL} -C backend/_build/prod/rel buttonlog

log "Created: ${TARBALL}"

# =============================================================================
# Step 4: Upload to Server
# =============================================================================
step "Uploading to server..."
scp -P ${SERVER_PORT} ${TARBALL} ${SERVER_USER}@${SERVER_HOST}:/tmp/

# =============================================================================
# Step 5: Deploy on Server
# =============================================================================
step "Deploying on server..."

ssh -p ${SERVER_PORT} ${SERVER_USER}@${SERVER_HOST} << REMOTE_SCRIPT
set -euo pipefail

echo "Creating release directory..."
mkdir -p ${RELEASE_DIR}

echo "Extracting release..."
tar -xzf /tmp/${RELEASE_NAME}.tar.gz -C ${RELEASE_DIR}

echo "Running migrations..."
cd ${RELEASE_DIR}
source ${APP_DIR}/config/.env
./buttonlog/bin/buttonlog eval "ButtonLog.Release.migrate()"

echo "Updating current symlink..."
ln -sfn ${RELEASE_DIR}/buttonlog ${CURRENT_LINK}

echo "Restarting application..."
sudo systemctl restart buttonlog

echo "Cleaning up..."
rm /tmp/${RELEASE_NAME}.tar.gz

# Keep only last 5 releases
cd ${RELEASES_DIR}
ls -t | tail -n +6 | xargs -r rm -rf

echo "Deployment complete!"
REMOTE_SCRIPT

# =============================================================================
# Step 6: Verify Deployment
# =============================================================================
step "Verifying deployment..."
sleep 5

# Check if service is running
if ssh -p ${SERVER_PORT} ${SERVER_USER}@${SERVER_HOST} "systemctl is-active --quiet buttonlog"; then
    log "Service is running"
else
    error "Service failed to start! Check logs with: journalctl -u buttonlog -f"
fi

# Health check
if ssh -p ${SERVER_PORT} ${SERVER_USER}@${SERVER_HOST} "curl -sf http://localhost:4000/health > /dev/null"; then
    log "Health check passed"
else
    warn "Health check failed - service may still be starting"
fi

# =============================================================================
# Cleanup
# =============================================================================
rm -f ${TARBALL}

# =============================================================================
# Done!
# =============================================================================
echo ""
log "=========================================="
log "Deployment successful!"
log "Version: ${VERSION}"
log "=========================================="
echo ""
echo "Useful commands:"
echo "  View logs:    ssh ${SERVER_USER}@${SERVER_HOST} 'journalctl -u buttonlog -f'"
echo "  Check status: ssh ${SERVER_USER}@${SERVER_HOST} 'systemctl status buttonlog'"
echo "  Rollback:     ./deploy/scripts/rollback.sh"
