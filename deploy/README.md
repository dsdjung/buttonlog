# ButtonLog Deployment

This directory contains all deployment configurations and documentation for ButtonLog.

## Quick Links

| Document | Description |
|----------|-------------|
| [DEPLOYMENT.md](DEPLOYMENT.md) | Backend deployment to VPS/Linode |
| [MOBILE_DEPLOYMENT.md](MOBILE_DEPLOYMENT.md) | iOS & Android app store deployment |

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         ButtonLog                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────┐     ┌─────────────┐     ┌─────────────┐       │
│  │   iOS App   │     │ Android App │     │   Web App   │       │
│  │ (App Store) │     │(Play Store) │     │ (Browser)   │       │
│  └──────┬──────┘     └──────┬──────┘     └──────┬──────┘       │
│         │                   │                   │               │
│         └───────────────────┼───────────────────┘               │
│                             │                                    │
│                             ▼                                    │
│                    ┌────────────────┐                           │
│                    │  Phoenix API   │                           │
│                    │  (Linode VPS)  │                           │
│                    └────────┬───────┘                           │
│                             │                                    │
│                             ▼                                    │
│                    ┌────────────────┐                           │
│                    │  PostgreSQL    │                           │
│                    │   (Managed)    │                           │
│                    └────────────────┘                           │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Deployment Methods

### 1. Manual Deployment

```bash
# Backend
./deploy/scripts/deploy.sh

# Android
cd android && bundle exec fastlane deploy_internal

# iOS
cd iphone && bundle exec fastlane deploy_testflight
```

### 2. GitHub Actions (Recommended)

All deployments can be triggered via GitHub Actions:

- **Backend**: Actions → "Deploy to Production" → Run workflow
- **Android**: Actions → "Android CI/CD" → Run workflow → Select track
- **iOS**: Actions → "iOS CI/CD" → Run workflow → Select track

## Environment Setup

### Required Secrets (GitHub)

#### Backend
- `DEPLOY_SSH_KEY` - SSH private key for server access

#### Android
- `ANDROID_KEYSTORE_BASE64` - Release keystore
- `ANDROID_KEYSTORE_PASSWORD` - Keystore password
- `ANDROID_KEY_ALIAS` - Signing key alias
- `ANDROID_KEY_PASSWORD` - Key password
- `GOOGLE_PLAY_JSON_KEY` - Play Store API credentials

#### iOS
- `APPLE_ID` - Apple Developer email
- `APPLE_TEAM_ID` - Team ID
- `APP_STORE_CONNECT_API_KEY_ID` - API Key ID
- `APP_STORE_CONNECT_API_ISSUER_ID` - Issuer ID
- `APP_STORE_CONNECT_API_KEY_CONTENT` - .p8 key content
- `MATCH_GIT_URL` - Certificates repo URL
- `MATCH_PASSWORD` - Match encryption password

### Required Variables (GitHub)

- `DEPLOY_HOST` - Backend server hostname
- `DEPLOY_USER` - SSH username (default: buttonlog)
- `DEPLOY_PORT` - SSH port (default: 22)

## Directory Structure

```
deploy/
├── README.md                 # This file
├── DEPLOYMENT.md             # Backend deployment guide
├── MOBILE_DEPLOYMENT.md      # Mobile apps deployment guide
├── docker/
│   ├── Dockerfile            # Production Docker image
│   ├── docker-compose.yml    # Local development
│   └── docker-compose.prod.yml
└── scripts/
    ├── deploy.sh             # Backend deployment script
    ├── rollback.sh           # Rollback script
    ├── setup-server.sh       # Initial server setup
    └── remote-commands.sh    # Remote management commands
```

## CI/CD Workflows

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `ci.yml` | Push/PR | Run tests, build artifacts |
| `deploy.yml` | Manual | Deploy backend to production |
| `android.yml` | Push/Manual | Build & deploy Android app |
| `ios.yml` | Push/Manual | Build & deploy iOS app |

## Release Process

### 1. Prepare Release

```bash
# Update version numbers
# - backend/mix.exs (version)
# - android/app/build.gradle.kts (versionName, versionCode)
# - iphone: Xcode project settings

# Create release branch
git checkout -b release/v1.2.0

# Update changelog
vim CHANGELOG.md

# Commit and push
git add -A && git commit -m "Prepare release v1.2.0"
git push -u origin release/v1.2.0
```

### 2. Deploy to Staging/Beta

```bash
# Backend: Deploy to staging
./deploy/scripts/deploy.sh staging

# Android: Deploy to internal testing
cd android && bundle exec fastlane deploy_internal

# iOS: Deploy to TestFlight
cd iphone && bundle exec fastlane deploy_testflight
```

### 3. Test & Verify

- Test on physical devices
- Verify API connectivity
- Check push notifications
- Test OAuth flows

### 4. Deploy to Production

```bash
# Merge to main
git checkout main && git merge release/v1.2.0

# Tag release
git tag -a v1.2.0 -m "Release 1.2.0"
git push origin main --tags

# Deploy via GitHub Actions or manually
```

## Monitoring & Observability

### Backend
- Health check: `https://your-domain.com/health`
- Logs: `journalctl -u buttonlog -f`
- Live Dashboard: `https://your-domain.com/dev/dashboard` (dev only)

### Mobile
- Android: Google Play Console → Release dashboard
- iOS: App Store Connect → App Analytics

## Support

For issues with deployment:
1. Check the troubleshooting section in relevant guide
2. Review GitHub Actions logs
3. Open an issue at https://github.com/dsdjung/buttonlog/issues
