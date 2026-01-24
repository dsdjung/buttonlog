# iOS Push Notifications Setup Guide

This guide explains how to configure iOS push notifications for ButtonLog using Apple Push Notification service (APNs).

## Overview

ButtonLog uses APNs HTTP/2 provider API with JWT-based authentication. This modern approach:
- Requires no certificate management or renewal
- Uses a single key for all apps in your team
- Supports both sandbox (development) and production environments

## Prerequisites

1. Apple Developer Program membership
2. App ID with Push Notifications capability enabled
3. Bundle ID: `com.buttonlog.app` (or your custom bundle ID)

## Step 1: Create APNs Key in Apple Developer Portal

1. Go to [Apple Developer Portal](https://developer.apple.com/account)
2. Navigate to **Certificates, Identifiers & Profiles** > **Keys**
3. Click the **+** button to create a new key
4. Enter a key name (e.g., "ButtonLog Push Key")
5. Enable **Apple Push Notifications service (APNs)**
6. Click **Continue**, then **Register**
7. **IMPORTANT**: Download the key file (`.p8`) - you can only download it once!
8. Note the **Key ID** displayed on the confirmation page
9. Note your **Team ID** (visible in the top-right of the portal, or in Membership details)

## Step 2: Configure iOS App

The iOS app is already configured with push notification capabilities:

### Entitlements (ButtonLog.entitlements)
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>aps-environment</key>
    <string>development</string>
</dict>
</plist>
```

### Info.plist Background Modes
```xml
<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
</array>
```

For production builds, change `aps-environment` to `production`.

## Step 3: Configure Backend Environment

Add the following environment variables to your `.env` file:

```bash
# Apple Push Notification Service (APNs)
export APNS_KEY_ID="XXXXXXXXXX"           # 10-character Key ID from Apple
export APNS_TEAM_ID="XXXXXXXXXX"          # 10-character Team ID
export APNS_BUNDLE_ID="com.buttonlog.app" # Your app's bundle identifier

# Option A: Path to the .p8 key file
export APNS_KEY_PATH="/path/to/AuthKey_XXXXXXXXXX.p8"

# Option B: Inline key content (useful for deployment platforms)
# Replace newlines with \n when setting as env var
export APNS_KEY_CONTENT="-----BEGIN PRIVATE KEY-----\nMIGT...your-key-content...\n-----END PRIVATE KEY-----"

# Environment: "sandbox" for development, "production" for App Store builds
export APNS_ENVIRONMENT="sandbox"
```

## Step 4: Test Push Notifications

### From iOS Simulator
The iOS Simulator does not support push notifications. Use a physical device for testing.

### From Physical Device
1. Run the app on a physical device
2. Grant notification permissions when prompted
3. The device token will be registered with the backend
4. Trigger a notification (e.g., friend request, button click alert)

### Verify Device Registration
```elixir
# In IEx console
user = ButtonLog.Accounts.get_user_by_email("test@example.com")
ButtonLog.Mobile.get_active_connections(user.id)
```

### Send Test Notification
```elixir
# In IEx console
ButtonLog.PushNotifications.send_to_user(
  user_id,
  "Test Notification",
  "This is a test push notification",
  %{"type" => "test"}
)
```

## Troubleshooting

### Common APNs Error Codes

| Status | Reason | Solution |
|--------|--------|----------|
| 400 | BadDeviceToken | Device token is invalid or malformed |
| 403 | InvalidProviderToken | JWT is invalid - check key_id, team_id, and key |
| 403 | ExpiredProviderToken | JWT expired - tokens cached for 50 minutes |
| 404 | Unregistered | Device token no longer valid - user uninstalled app |
| 410 | Unregistered | Device token explicitly marked as inactive |

### Debug Logging

Enable debug logging to see APNs requests:
```elixir
# In config/dev.exs
config :logger, level: :debug
```

### JWT Token Verification

Test JWT generation:
```elixir
# In IEx console
ButtonLog.PushNotifications.get_apns_jwt()
```

### Verify Configuration
```elixir
# Check if APNs is configured
Application.get_env(:buttonlog, :apns)
```

## Architecture

### Token Flow
1. iOS app requests notification permission
2. iOS registers with APNs and receives device token
3. App sends device token to backend via `/api/mobile/register`
4. Backend stores token in `mobile_connections` table
5. When notification needed, backend generates JWT and sends to APNs
6. APNs delivers notification to device

### JWT Authentication
- APNs JWT tokens are generated using ES256 algorithm
- Tokens are cached for 50 minutes (APNs allows 60 min max)
- Signed using your team's .p8 private key

### HTTP/2 Connection Pooling
- Uses Finch library for HTTP/2 support
- Maintains persistent connections to APNs
- Separate pools for sandbox and production endpoints

## Production Deployment

1. Update `APNS_ENVIRONMENT` to `production`
2. Update `aps-environment` in entitlements to `production`
3. Ensure your app is signed with a production provisioning profile
4. Deploy the updated backend configuration

## Security Notes

- **Never commit** the .p8 key file to version control
- Use environment variables or secret management for key storage
- The same key works for all apps under your team
- Keys do not expire but can be revoked in the Apple Developer Portal
