# ButtonLog Mobile App Deployment Guide

This guide covers deploying ButtonLog mobile apps to Google Play Store and Apple App Store.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Android Deployment](#android-deployment)
3. [iOS Deployment](#ios-deployment)
4. [CI/CD Setup](#cicd-setup)
5. [Version Management](#version-management)
6. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Local Development Tools

```bash
# macOS (required for iOS)
xcode-select --install

# Ruby (for Fastlane)
brew install ruby
gem install fastlane

# Android
brew install --cask android-studio
```

### Accounts Required

| Platform | Account Type | Purpose |
|----------|-------------|---------|
| Google Play | Developer Account ($25 one-time) | Android app distribution |
| Apple | Developer Account ($99/year) | iOS app distribution |
| App Store Connect | Same as Apple Developer | iOS submission & TestFlight |

---

## Android Deployment

### Initial Setup

#### 1. Create Google Play Developer Account

1. Go to [Google Play Console](https://play.google.com/console)
2. Pay the $25 registration fee
3. Complete account verification

#### 2. Create App in Play Console

1. Click "Create app"
2. Fill in app details:
   - App name: ButtonLog
   - Default language: English
   - App or game: App
   - Free or paid: Free
3. Complete the store listing

#### 3. Generate Signing Key

```bash
cd android

# Generate release keystore
keytool -genkey -v -keystore release-keystore.jks \
    -keyalg RSA -keysize 2048 -validity 10000 \
    -alias buttonlog

# IMPORTANT: Save the passwords securely!
# Store keystore in a safe location (not in git)
```

#### 4. Set Up Play Store API Access

1. Go to Play Console → Setup → API access
2. Create a service account
3. Grant "Release Manager" permissions
4. Download JSON key file
5. Save as `android/fastlane/play-store-credentials.json`

### Manual Deployment

```bash
cd android

# Build release AAB
./gradlew bundleRelease

# Deploy to internal testing
bundle exec fastlane deploy_internal

# Deploy to beta (closed testing)
bundle exec fastlane deploy_beta

# Deploy to production
bundle exec fastlane deploy_production
```

### Environment Variables (Android)

```bash
# Required for signing
export KEYSTORE_FILE=/path/to/release-keystore.jks
export KEYSTORE_PASSWORD=your-keystore-password
export KEY_ALIAS=buttonlog
export KEY_PASSWORD=your-key-password

# For Play Store upload
export GOOGLE_PLAY_JSON_KEY=/path/to/play-store-credentials.json
```

---

## iOS Deployment

### Initial Setup

#### 1. Apple Developer Account

1. Enroll at [developer.apple.com](https://developer.apple.com)
2. Pay $99/year membership
3. Complete verification

#### 2. Create App ID & Certificates

1. Go to [Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources)
2. Create App ID:
   - Bundle ID: `com.buttonlog.app`
   - Enable: Push Notifications, Sign in with Apple
3. Create certificates:
   - iOS Distribution Certificate
   - Apple Push Notification service (APNs) Key

#### 3. Create App in App Store Connect

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Click "My Apps" → "+"
3. Fill in app details:
   - Platform: iOS
   - Name: ButtonLog
   - Primary Language: English
   - Bundle ID: com.buttonlog.app
   - SKU: buttonlog-ios

#### 4. Set Up Code Signing with Match

```bash
cd iphone

# Initialize match (first time only)
fastlane match init

# Generate App Store certificates
fastlane match appstore

# Generate development certificates
fastlane match development
```

#### 5. Create App Store Connect API Key

1. Go to App Store Connect → Users and Access → Keys
2. Click "+" to generate a new key
3. Name: "CI/CD Deploy"
4. Access: App Manager
5. Download the `.p8` file
6. Note the Key ID and Issuer ID

### Manual Deployment

```bash
cd iphone

# Build and deploy to TestFlight
bundle exec fastlane deploy_testflight

# Deploy to beta testers
bundle exec fastlane deploy_beta

# Deploy to App Store
bundle exec fastlane deploy_production

# Submit for review
bundle exec fastlane submit_for_review
```

### Environment Variables (iOS)

```bash
# Apple credentials
export APPLE_ID=your-apple-id@example.com
export APPLE_TEAM_ID=5R2YZH47Y4

# App Store Connect API
export APP_STORE_CONNECT_API_KEY_ID=your-key-id
export APP_STORE_CONNECT_API_ISSUER_ID=your-issuer-id
export APP_STORE_CONNECT_API_KEY_CONTENT=$(cat path/to/AuthKey.p8)

# Match (code signing)
export MATCH_GIT_URL=https://github.com/your-org/certificates.git
export MATCH_PASSWORD=your-match-password
```

---

## CI/CD Setup

### GitHub Secrets Required

#### Android Secrets

| Secret | Description |
|--------|-------------|
| `ANDROID_KEYSTORE_BASE64` | Base64-encoded release keystore |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore password |
| `ANDROID_KEY_ALIAS` | Key alias (e.g., "buttonlog") |
| `ANDROID_KEY_PASSWORD` | Key password |
| `GOOGLE_PLAY_JSON_KEY` | Play Store API credentials JSON |

```bash
# Encode keystore to base64
base64 -i android/release-keystore.jks | pbcopy
```

#### iOS Secrets

| Secret | Description |
|--------|-------------|
| `APPLE_ID` | Apple Developer email |
| `APPLE_TEAM_ID` | Team ID (e.g., "5R2YZH47Y4") |
| `APP_STORE_CONNECT_API_KEY_ID` | API Key ID |
| `APP_STORE_CONNECT_API_ISSUER_ID` | API Issuer ID |
| `APP_STORE_CONNECT_API_KEY_CONTENT` | Contents of .p8 key file |
| `MATCH_GIT_URL` | Git repo for certificates |
| `MATCH_PASSWORD` | Match encryption password |
| `MATCH_GIT_BASIC_AUTHORIZATION` | Base64(username:token) |

### Triggering Deployments

#### Via GitHub Actions UI

1. Go to Actions tab
2. Select "Android CI/CD" or "iOS CI/CD"
3. Click "Run workflow"
4. Select deployment track:
   - `internal` / `testflight` - Internal testing
   - `beta` - External beta testers
   - `production` - Public release

#### Via Git Tags

```bash
# Tag and push for release
git tag -a v1.2.0 -m "Release 1.2.0"
git push origin v1.2.0
```

---

## Version Management

### Semantic Versioning

Format: `MAJOR.MINOR.PATCH`

- **MAJOR**: Breaking changes
- **MINOR**: New features (backwards compatible)
- **PATCH**: Bug fixes

### Version Code (Android)

Automatically incremented by Fastlane based on timestamp.

Manual override:
```bash
VERSION_CODE=42 bundle exec fastlane deploy_internal
```

### Build Number (iOS)

Automatically incremented by Fastlane based on timestamp.

Manual override:
```bash
BUILD_NUMBER=42 bundle exec fastlane deploy_testflight
```

### Updating Version

#### Android (build.gradle.kts)
```kotlin
defaultConfig {
    versionCode = 2
    versionName = "1.1.0"
}
```

#### iOS (Xcode)
1. Select project in navigator
2. Select target → General
3. Update Version and Build

---

## Troubleshooting

### Android Issues

#### "App signing certificate not found"
```bash
# Ensure keystore is set up correctly
keytool -list -v -keystore release-keystore.jks
```

#### "Upload failed: Version code already used"
```bash
# Set a higher version code
VERSION_CODE=999 bundle exec fastlane deploy_internal
```

### iOS Issues

#### "No signing certificate found"
```bash
# Regenerate certificates
fastlane match appstore --force
```

#### "Invalid provisioning profile"
```bash
# Clear derived data and re-sign
rm -rf ~/Library/Developer/Xcode/DerivedData
fastlane match appstore
```

#### "App Store Connect upload failed"
- Verify API key permissions
- Check for missing metadata in App Store Connect
- Ensure screenshots are uploaded

### General Issues

#### "Fastlane not found"
```bash
gem install fastlane
# Or use bundle
bundle install
bundle exec fastlane ...
```

#### "Authentication failed"
- Verify environment variables are set
- Check API key/credentials haven't expired
- Ensure correct permissions are granted

---

## Release Checklist

### Before Each Release

- [ ] Update version number
- [ ] Update changelog/release notes
- [ ] Run all tests locally
- [ ] Test on physical devices
- [ ] Review crash reports from previous version
- [ ] Update app store metadata if needed

### Android Release

- [ ] Build signed AAB
- [ ] Test on multiple Android versions
- [ ] Upload to internal track first
- [ ] Promote to beta after testing
- [ ] Monitor crash reports
- [ ] Promote to production with staged rollout

### iOS Release

- [ ] Build with release configuration
- [ ] Test on multiple iOS versions
- [ ] Upload to TestFlight
- [ ] Test with external beta group
- [ ] Submit for App Store review
- [ ] Monitor for review feedback
- [ ] Release after approval

---

## Cost Summary

| Item | Cost | Frequency |
|------|------|-----------|
| Google Play Developer | $25 | One-time |
| Apple Developer Program | $99 | Annual |
| **Total First Year** | **$124** | |
| **Subsequent Years** | **$99** | Annual |
