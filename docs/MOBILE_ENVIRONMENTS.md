# Mobile App Environment Configuration

ButtonLog mobile apps (iOS and Android) support multiple environments for development, staging, and production.

## Environments

| Environment | API URL | Use Case |
|-------------|---------|----------|
| **Development** | `http://localhost:14015/api` (iOS) / `http://10.0.2.2:14015/api/` (Android) | Local development against your machine |
| **Staging** | `https://staging.buttonlog.com/api` | Testing against the staging server |
| **Production** | `https://buttonlog.com/api` | App Store / Play Store release |

---

## iOS Configuration

### How It Works

iOS uses a combination of:
1. **xcconfig files** - Define environment-specific build settings
2. **Info.plist** - Contains `APP_ENVIRONMENT` key that reads from build settings
3. **Environment.swift** - Runtime configuration that reads from Info.plist

### Build Configurations

| Configuration | xcconfig File | Bundle ID |
|---------------|---------------|-----------|
| Development | `Configuration/Development.xcconfig` | `com.buttonlog.app.dev` |
| Staging | `Configuration/Staging.xcconfig` | `com.buttonlog.app.staging` |
| Production | `Configuration/Production.xcconfig` | `com.buttonlog.app` |

### Setting Up in Xcode

1. Open the project in Xcode
2. Go to **Project Settings** > **Info** tab
3. Under **Configurations**, set the appropriate xcconfig file for each build configuration:
   - Debug: Use `Development.xcconfig`
   - Release: Use `Production.xcconfig`
4. For staging, create a new build configuration:
   - Click the **+** button under Configurations
   - Duplicate "Release" and name it "Staging"
   - Set it to use `Staging.xcconfig`

### Running Different Environments

**Development (Default Debug):**
```bash
# Just run the app from Xcode with Debug configuration
```

**Staging:**
1. Edit Scheme (Product > Scheme > Edit Scheme)
2. Change Build Configuration to "Staging"
3. Run the app

**Production:**
1. Archive the app with Release configuration

**Quick Override (Debug only):**
You can also use launch arguments:
```
-staging    # Use staging environment
-production # Use production environment
```

Add these in Xcode: Product > Scheme > Edit Scheme > Run > Arguments

---

## Android Configuration

### How It Works

Android uses **Product Flavors** defined in `app/build.gradle.kts`:
- Each flavor defines `BuildConfig` fields for API URLs
- The `ApiConfig` object reads from these `BuildConfig` fields at runtime

### Product Flavors

| Flavor | App ID | API URL |
|--------|--------|---------|
| `development` | `com.buttonlog.app.dev` | `http://10.0.2.2:14015/api/` |
| `staging` | `com.buttonlog.app.staging` | `https://staging.buttonlog.com/api/` |
| `production` | `com.buttonlog.app` | `https://buttonlog.com/api/` |

### Build Variants

Android Studio shows these build variants:
- `developmentDebug` - Development + Debug
- `developmentRelease` - Development + Release
- `stagingDebug` - Staging + Debug
- `stagingRelease` - Staging + Release
- `productionDebug` - Production + Debug
- `productionRelease` - Production + Release (App Store)

### Running Different Environments

1. Open Android Studio
2. Go to **Build > Select Build Variant** (or View > Tool Windows > Build Variants)
3. Select the desired variant from the dropdown
4. Run the app

### Command Line

```bash
# Development Debug
./gradlew assembleDevelopmentDebug

# Staging Debug
./gradlew assembleStagingDebug

# Production Release (for Play Store)
./gradlew assembleProductionRelease
```

---

## Testing with Physical Devices

### iOS Physical Device + Local Backend

When testing on a physical iPhone against your Mac's local backend:

1. Find your Mac's local IP: `ifconfig | grep "inet " | grep -v 127.0.0.1`
2. Update `Environment.swift` development case to use your IP:
   ```swift
   case .development:
       return "http://YOUR_MAC_IP:14015/api"
   ```
3. Or use a launch argument: `-api-host=YOUR_MAC_IP`

### Android Physical Device + Local Backend

When testing on a physical Android device:

1. Ensure device and Mac are on same network
2. Find your Mac's local IP
3. Temporarily modify the development flavor in `build.gradle.kts`:
   ```kotlin
   buildConfigField("String", "API_BASE_URL", "\"http://YOUR_MAC_IP:14015/api/\"")
   ```
4. Or use ADB reverse port forwarding:
   ```bash
   adb reverse tcp:14015 tcp:14015
   ```
   Then use `http://localhost:14015/api/` on the device

---

## Environment Indicator (Optional)

Both apps display the environment name when not in production. This helps testers identify which environment they're using.

### iOS
The environment is logged at startup and can be displayed in UI:
```swift
if AppConfiguration.shared.environment != .production {
    Text(AppConfiguration.shared.environment.displayName)
}
```

### Android
Check `BuildConfig.DEBUG_LOGGING` or flavor name:
```kotlin
if (BuildConfig.DEBUG_LOGGING) {
    // Show environment indicator
}
```

---

## Troubleshooting

### iOS: Wrong environment being used
1. Clean build folder: Product > Clean Build Folder (Cmd+Shift+K)
2. Delete derived data: ~/Library/Developer/Xcode/DerivedData
3. Verify xcconfig is set correctly in project settings

### Android: BuildConfig not updating
1. Clean project: Build > Clean Project
2. Rebuild: Build > Rebuild Project
3. Invalidate caches: File > Invalidate Caches / Restart

### Network requests failing
1. **iOS**: Check App Transport Security settings in Info.plist
2. **Android**: Check network security config for cleartext traffic (development only)
3. Verify the backend is running and accessible
