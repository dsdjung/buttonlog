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

### Account Features

#### Edit Profile (iOS, Android, Web)
- [ ] Load current profile data on screen open
- [ ] Edit display name and save
- [ ] Edit first/last name and save
- [ ] Verify changes persist after app restart
- [ ] Test with empty optional fields
- [ ] Test validation (required fields)

#### Privacy Settings (iOS, Android, Web)
- [ ] Load current visibility settings
- [ ] Change profile visibility (Public/Friends/Private)
- [ ] Change activity visibility (Public/Friends/Private)
- [ ] Verify settings persist after save
- [ ] Verify privacy is enforced (view as another user)

#### Notification Settings (iOS, Android, Web)
- [ ] Load current notification preferences
- [ ] Toggle push notifications on/off
- [ ] Toggle email notifications on/off
- [ ] Toggle button activity notifications
- [ ] Toggle friend update notifications
- [ ] Toggle system notifications
- [ ] Enable/disable quiet hours
- [ ] Verify settings persist after save
- [ ] Test that sub-toggles disable when push notifications off

#### Password Management (iOS, Android, Web)
- [ ] Enter current password + new password + confirm
- [ ] Submit and verify success message
- [ ] Log out and log in with new password
- [ ] Test wrong current password (should fail)
- [ ] Test mismatched passwords (should fail)
- [ ] Test too short password (<8 chars, should fail)

#### Data Export (iOS, Android, Web)
- [ ] View export info (button count, click count, friend count)
- [ ] Export as JSON format
- [ ] Export as CSV format
- [ ] Verify file contains user profile data
- [ ] Verify file contains all buttons
- [ ] Verify file contains click history
- [ ] Verify file contains friend list
- [ ] Share/save exported file successfully

#### About Page (iOS, Android, Web)
- [ ] View app version and build number
- [ ] Tap Terms of Service link - opens correctly
- [ ] Tap Privacy Policy link - opens correctly
- [ ] View contact information
- [ ] View acknowledgements/credits

#### Webhook Settings (iOS, Android, Web)
- [ ] Load current webhook configuration
- [ ] Enter webhook URL
- [ ] Toggle webhook enabled/disabled
- [ ] Set webhook secret
- [ ] Configure retry settings
- [ ] Save settings and verify persistence
- [ ] Test webhook button - verify delivery
- [ ] View delivery history (Web only)

### Cross-Platform Consistency Checks

#### iOS vs Android vs Web
- [ ] Same fields available on all platforms
- [ ] Same validation rules on all platforms
- [ ] Same error messages for same errors
- [ ] Consistent UI/UX patterns
- [ ] Data syncs correctly across platforms

### API Endpoint Verification

| Endpoint | Method | Test |
|----------|--------|------|
| `/api/users/profile` | GET | Returns current user data |
| `/api/users/profile` | PUT | Updates profile fields |
| `/api/users/password` | PUT | Changes password |
| `/api/users/notification-preferences` | GET | Returns notification prefs |
| `/api/users/notification-preferences` | PUT | Updates notification prefs |
| `/api/users/export` | GET | Returns JSON/CSV export |
| `/api/users/export/info` | GET | Returns export metadata |
| `/api/notifications/settings` | GET | Returns webhook settings |
| `/api/notifications/settings` | PUT | Updates webhook settings |
| `/api/notifications/test` | POST | Tests webhook delivery |

### Error Handling Tests

- [ ] Network offline - graceful error message
- [ ] Invalid auth token - redirects to login
- [ ] Server error (500) - user-friendly message
- [ ] Validation errors - specific field errors shown
- [ ] Timeout handling - retry or error message

### Regression Tests

- [ ] Existing button functionality works
- [ ] Friend requests/accepts work
- [ ] Notifications received correctly
- [ ] Subscription features work
- [ ] Login/logout works
- [ ] OAuth login works (Google, Facebook, Apple)

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


