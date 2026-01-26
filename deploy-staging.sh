#!/bin/bash
# ButtonLog Staging Deployment Script

set -e

# Configuration
SERVER="deploy@45.33.107.135"
APP_DIR="/opt/buttonlog"
BACKEND_DIR="$(dirname "$0")/backend"

echo "==> Building release for staging..."
cd "$BACKEND_DIR"

# Install dependencies
mix deps.get --only prod

# Build assets
cd assets
npm install
npm run build
cd ..

# Compile and build release
MIX_ENV=prod mix compile
MIX_ENV=prod mix assets.deploy
MIX_ENV=prod mix release --overwrite

echo "==> Deploying to staging server..."
RELEASE_TAR="_build/prod/buttonlog-*.tar.gz"

# Create tarball from release
cd _build/prod/rel/buttonlog
tar czf ../../../../buttonlog-release.tar.gz .
cd ../../../..

# Upload release
scp buttonlog-release.tar.gz $SERVER:/tmp/

# Deploy on server
ssh $SERVER "
    set -e
    cd $APP_DIR

    # Stop existing service (if running)
    sudo systemctl stop buttonlog || true

    # Backup current release
    [ -d bin ] && mv bin bin.backup.\$(date +%Y%m%d%H%M%S) || true

    # Extract new release
    tar xzf /tmp/buttonlog-release.tar.gz
    rm /tmp/buttonlog-release.tar.gz

    # Run migrations
    source .env
    ./bin/buttonlog eval 'ButtonLog.Release.migrate()'

    # Start service
    sudo systemctl start buttonlog
    sleep 3
    sudo systemctl status buttonlog
"

echo "==> Cleaning up..."
rm buttonlog-release.tar.gz

echo "==> Deployment complete!"
echo "Visit: https://staging.buttonlog.com"
