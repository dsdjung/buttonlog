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

## Manual Testing Checklist

These tests require human verification and cannot be easily automated.

### Device-Specific Features (Physical Device Required)

#### Push Notifications
- [ ] iOS: Receive push notification on physical device
- [ ] Android: Receive push notification on physical device
- [ ] Tap notification navigates to correct screen
- [ ] Notification badge count updates correctly

#### Data Export File Sharing
- [ ] iOS: Share sheet opens with export file
- [ ] iOS: Save to Files app works
- [ ] iOS: AirDrop file to another device
- [ ] Android: Share intent opens with export file
- [ ] Android: Save to device storage works

#### OAuth Authentication
- [ ] Google Sign-In flow completes on iOS
- [ ] Google Sign-In flow completes on Android
- [ ] Apple Sign-In flow completes on iOS
- [ ] Facebook Login flow completes (if enabled)

### Visual/UI Verification

#### Cross-Platform Consistency
- [ ] Edit Profile: Same fields and layout across iOS/Android/Web
- [ ] Privacy Settings: Radio buttons/pickers appear correctly
- [ ] Notification Settings: Toggles align and function identically
- [ ] About Page: Version info displays correctly per platform
- [ ] Webhook Settings: Form layout consistent across platforms

#### Responsive Design (Web)
- [ ] Account page renders correctly on mobile viewport
- [ ] Account page renders correctly on tablet viewport
- [ ] Account page renders correctly on desktop viewport

#### Dark Mode (if supported)
- [ ] All account screens readable in dark mode
- [ ] No contrast issues with form elements

### External URL Handling

#### Terms & Privacy Links
- [ ] iOS: Terms link opens in Safari/WebView correctly
- [ ] iOS: Privacy link opens in Safari/WebView correctly
- [ ] Android: Terms link opens in Chrome/WebView correctly
- [ ] Android: Privacy link opens in Chrome/WebView correctly

#### Webhook External Delivery
- [ ] Test webhook delivers to external URL (e.g., webhook.site)
- [ ] Webhook payload contains expected data structure

### Accessibility

- [ ] VoiceOver (iOS) can navigate account screens
- [ ] TalkBack (Android) can navigate account screens
- [ ] Screen reader announces form labels correctly
- [ ] Sufficient color contrast for all text

---

## Feature Plans (Future)

- Analytics History
- Calendar Sync
- API Access
- Priority Support
- Custom Themes
- Team Features
- Enterprise Features

---

## Completed Features (January 2025)

### Phase 1-3 (Previously completed)
- [x] Edit Profile - Backend API + iOS/Android/Web UIs
- [x] Privacy Settings - Backend API + iOS/Android/Web UIs
- [x] Notification Settings - Backend migration + iOS/Android/Web UIs

### Phase 4-8 (This session)
- [x] Password Management - Full stack implementation
- [x] Data Export - JSON/CSV export with file sharing
- [x] About Pages - iOS, Android, Web
- [x] Terms of Service / Privacy Policy - Web pages with legal content
- [x] Webhook Notifications on Mobile - iOS and Android screens

### Test Coverage Added
- [x] Password controller tests (5 test cases)
- [x] Export controller tests (9 test cases)
- [x] Data export module tests (9 test cases)


