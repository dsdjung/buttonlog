#!/bin/bash
# Run multi-user friend tests on two Android emulators in parallel
#
# Prerequisites:
# 1. Two Android emulators running with ButtonLog app installed
# 2. User 1 authenticated on first emulator
# 3. User 2 authenticated on second emulator
#
# Usage: ./scripts/run-multi-user-android.sh

set -e

# Add Maestro to PATH
export PATH="$PATH:$HOME/.maestro/bin"

echo ""
echo "========================================"
echo "Android Multi-User Friend Tests"
echo "========================================"
echo ""

# Get list of connected Android devices/emulators
DEVICES=$(adb devices | grep -v "List" | grep "device$" | cut -f1)
DEVICE_COUNT=$(echo "$DEVICES" | grep -c . || echo 0)

if [ "$DEVICE_COUNT" -lt 2 ]; then
    echo "ERROR: Need at least 2 connected Android devices/emulators!"
    echo ""
    echo "Current connected devices: $DEVICE_COUNT"
    echo ""
    echo "To start emulators:"
    echo "  emulator -avd Pixel_6_API_33 &"
    echo "  emulator -avd Pixel_7_API_34 &"
    echo ""
    echo "List available AVDs with: emulator -list-avds"
    exit 1
fi

DEVICE1=$(echo "$DEVICES" | head -1)
DEVICE2=$(echo "$DEVICES" | tail -1)

echo "Using devices:"
echo "  User 1: $DEVICE1"
echo "  User 2: $DEVICE2"
echo ""

# Run tests in parallel
echo "Starting User 1 tests on $DEVICE1..."
maestro test --device "$DEVICE1" android/friends-multi-user1.yaml &
PID1=$!

echo "Starting User 2 tests on $DEVICE2..."
maestro test --device "$DEVICE2" android/friends-multi-user2.yaml &
PID2=$!

# Wait for both to complete
echo ""
echo "Running tests in parallel..."
echo ""

wait $PID1
STATUS1=$?

wait $PID2
STATUS2=$?

echo ""
echo "========================================"
echo "Results:"
echo "========================================"
echo "  User 1 tests: $([ $STATUS1 -eq 0 ] && echo 'PASSED' || echo 'FAILED')"
echo "  User 2 tests: $([ $STATUS2 -eq 0 ] && echo 'PASSED' || echo 'FAILED')"
echo ""

# Exit with failure if either failed
if [ $STATUS1 -ne 0 ] || [ $STATUS2 -ne 0 ]; then
    exit 1
fi

echo "All multi-user tests passed!"
