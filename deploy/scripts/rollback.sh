#!/bin/bash
# =============================================================================
# ButtonLog Rollback Script
# Quickly rollback to a previous release
# =============================================================================

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Configuration
SERVER_USER="buttonlog"
SERVER_HOST="${DEPLOY_HOST:-your-server.com}"
SERVER_PORT="${DEPLOY_PORT:-22}"
APP_DIR="/opt/buttonlog"
RELEASES_DIR="${APP_DIR}/releases"
CURRENT_LINK="${APP_DIR}/current"

# =============================================================================
# List Available Releases
# =============================================================================
if [[ "${1:-}" == "list" ]]; then
    echo "Available releases:"
    ssh -p ${SERVER_PORT} ${SERVER_USER}@${SERVER_HOST} "ls -lt ${RELEASES_DIR}"
    exit 0
fi

# =============================================================================
# Get Target Release
# =============================================================================
TARGET_RELEASE="${1:-}"

if [[ -z "${TARGET_RELEASE}" ]]; then
    echo "Usage: $0 <release-name|previous>"
    echo "       $0 list                    # List available releases"
    echo "       $0 previous                # Rollback to previous release"
    echo "       $0 buttonlog-20260124      # Rollback to specific release"
    exit 1
fi

# =============================================================================
# Perform Rollback
# =============================================================================
log "Starting rollback..."

ssh -p ${SERVER_PORT} ${SERVER_USER}@${SERVER_HOST} << REMOTE_SCRIPT
set -euo pipefail

cd ${RELEASES_DIR}

# Determine target release
if [[ "${TARGET_RELEASE}" == "previous" ]]; then
    # Get second most recent release
    CURRENT=\$(basename \$(readlink ${CURRENT_LINK}))
    TARGET=\$(ls -t | grep -v "\${CURRENT}" | head -1)
    if [[ -z "\${TARGET}" ]]; then
        echo "No previous release found!"
        exit 1
    fi
    echo "Rolling back from \${CURRENT} to \${TARGET}"
else
    TARGET="${TARGET_RELEASE}"
    if [[ ! -d "${RELEASES_DIR}/\${TARGET}" ]]; then
        echo "Release \${TARGET} not found!"
        echo "Available releases:"
        ls -t ${RELEASES_DIR}
        exit 1
    fi
fi

# Update symlink
echo "Updating symlink to \${TARGET}..."
ln -sfn ${RELEASES_DIR}/\${TARGET}/buttonlog ${CURRENT_LINK}

# Restart service
echo "Restarting service..."
sudo systemctl restart buttonlog

echo "Rollback complete!"
REMOTE_SCRIPT

# =============================================================================
# Verify Rollback
# =============================================================================
sleep 5

if ssh -p ${SERVER_PORT} ${SERVER_USER}@${SERVER_HOST} "systemctl is-active --quiet buttonlog"; then
    log "Rollback successful - service is running"
else
    error "Service failed to start after rollback!"
fi
