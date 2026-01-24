# ButtonLog Deployment Checklist

## Backend Deployment - READY

- [x] Docker configuration (deploy/docker/)
- [x] CI/CD pipeline (.github/workflows/ci.yml)
- [x] Production deployment workflow (.github/workflows/deploy.yml)
- [x] Deployment scripts (deploy/scripts/)
- [x] Documentation (deploy/DEPLOYMENT.md)

## Android Deployment - READY

- [x] Fastlane configuration (android/fastlane/)
- [x] CI/CD pipeline (.github/workflows/android.yml)
- [x] Build variants (debug/release)
- [x] Documentation (deploy/MOBILE_DEPLOYMENT.md)

### Android Setup Tasks (Manual)
- [ ] Create Google Play Developer Account ($25)
- [ ] Create app in Play Console
- [ ] Generate release signing keystore
- [ ] Set up Play Store API access
- [ ] Configure GitHub secrets

## iOS Deployment - READY

- [x] Fastlane configuration (iphone/fastlane/)
- [x] CI/CD pipeline (.github/workflows/ios.yml)
- [x] Code signing setup (Match)
- [x] Documentation (deploy/MOBILE_DEPLOYMENT.md)

### iOS Setup Tasks (Manual)
- [ ] Enroll in Apple Developer Program ($99/year)
- [ ] Create App ID in Developer Portal
- [ ] Create app in App Store Connect
- [ ] Set up Match for code signing
- [ ] Create App Store Connect API key
- [ ] Configure GitHub secrets

## Environment Configuration

### GitHub Secrets Required

#### Backend
- [ ] `DEPLOY_SSH_KEY` - SSH private key for server

#### Android
- [ ] `ANDROID_KEYSTORE_BASE64` - Release keystore (base64)
- [ ] `ANDROID_KEYSTORE_PASSWORD` - Keystore password
- [ ] `ANDROID_KEY_ALIAS` - Key alias
- [ ] `ANDROID_KEY_PASSWORD` - Key password
- [ ] `GOOGLE_PLAY_JSON_KEY` - Play Store API credentials

#### iOS
- [ ] `APPLE_ID` - Apple Developer email
- [ ] `APPLE_TEAM_ID` - Team ID
- [ ] `APP_STORE_CONNECT_API_KEY_ID` - API Key ID
- [ ] `APP_STORE_CONNECT_API_ISSUER_ID` - Issuer ID
- [ ] `APP_STORE_CONNECT_API_KEY_CONTENT` - .p8 key content
- [ ] `MATCH_GIT_URL` - Certificates repo URL
- [ ] `MATCH_PASSWORD` - Match encryption password

### GitHub Variables Required
- [ ] `DEPLOY_HOST` - Backend server hostname
- [ ] `DEPLOY_USER` - SSH username (default: buttonlog)

## Quick Start Commands

```bash
# Backend deployment
./deploy/scripts/deploy.sh

# Android - internal testing
cd android && bundle install && bundle exec fastlane deploy_internal

# iOS - TestFlight
cd iphone && bundle install && bundle exec fastlane deploy_testflight
```

## Documentation

- Backend: [deploy/DEPLOYMENT.md](deploy/DEPLOYMENT.md)
- Mobile: [deploy/MOBILE_DEPLOYMENT.md](deploy/MOBILE_DEPLOYMENT.md)
- Overview: [deploy/README.md](deploy/README.md)
