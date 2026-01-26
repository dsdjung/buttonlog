#!/bin/bash
# Run multi-user friend tests across iOS and Android
#
# User 1: iOS Simulator
# User 2: Android Emulator
#
# Prerequisites:
# 1. One iOS simulator running with ButtonLog app (User 1 authenticated)
# 2. One Android emulator running with ButtonLog app (User 2 authenticated)
#
# Usage: ./scripts/run-multi-user-cross-platform.sh

set -e

# Add Maestro and Android SDK to PATH
export PATH="$PATH:$HOME/.maestro/bin:$HOME/Library/Android/sdk/platform-tools"

echo ""
echo "========================================"
echo "Cross-Platform Multi-User Friend Tests"
echo "========================================"
echo ""
echo "  User 1: iOS Simulator"
echo "  User 2: Android Emulator"
echo ""

# Check for iOS simulator
IOS_SIM=$(xcrun simctl list devices | grep "Booted" | head -1 | sed 's/.*(\([A-F0-9-]*\)).*/\1/')
if [ -z "$IOS_SIM" ]; then
    echo "ERROR: No booted iOS simulator found!"
    echo "Boot a simulator with: xcrun simctl boot 'iPhone 16 Pro'"
    exit 1
fi
echo "iOS Simulator (User 1): $IOS_SIM"

# Check for Android emulator
ANDROID_DEVICE=$(adb devices | grep -v "List" | grep "device$" | head -1 | cut -f1)
if [ -z "$ANDROID_DEVICE" ]; then
    echo "ERROR: No connected Android device/emulator found!"
    echo "Start an emulator with: emulator -avd <avd-name>"
    exit 1
fi
echo "Android Emulator (User 2): $ANDROID_DEVICE"
echo ""

# Run tests sequentially
echo "Running User 1 tests on iOS ($IOS_SIM)..."
maestro test --device "$IOS_SIM" ios/friends-multi-user1.yaml
STATUS1=$?

echo ""
echo "Running User 2 tests on Android ($ANDROID_DEVICE)..."
maestro test --device "$ANDROID_DEVICE" android/friends-multi-user2.yaml
STATUS2=$?

echo ""
echo "========================================"
echo "Results:"
echo "========================================"
echo "  User 1 (iOS):     $([ $STATUS1 -eq 0 ] && echo 'PASSED' || echo 'FAILED')"
echo "  User 2 (Android): $([ $STATUS2 -eq 0 ] && echo 'PASSED' || echo 'FAILED')"
echo ""

# Exit with failure if either failed
if [ $STATUS1 -ne 0 ] || [ $STATUS2 -ne 0 ]; then
    exit 1
fi

echo "All cross-platform multi-user tests passed!"
