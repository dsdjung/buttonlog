#!/bin/bash
# List all available iOS simulators and Android emulators
#
# Usage: ./scripts/list-devices.sh

echo ""
echo "========================================"
echo "iOS Simulators"
echo "========================================"
echo ""

echo "Booted simulators:"
xcrun simctl list devices | grep "Booted" || echo "  (none)"

echo ""
echo "Available simulators (run 'xcrun simctl boot <name>' to start):"
xcrun simctl list devices available | grep -E "iPhone|iPad" | head -10

echo ""
echo "========================================"
echo "Android Devices/Emulators"
echo "========================================"
echo ""

echo "Connected devices:"
adb devices 2>/dev/null | grep -v "List" | grep "device" || echo "  (none or adb not available)"

echo ""
echo "Available AVDs (run 'emulator -avd <name> &' to start):"
if command -v emulator &> /dev/null; then
    emulator -list-avds 2>/dev/null || echo "  (none)"
else
    echo "  (emulator command not found)"
fi

echo ""
echo "========================================"
echo "Maestro Devices"
echo "========================================"
echo ""
maestro devices 2>/dev/null || echo "Maestro not installed. Run: curl -Ls 'https://get.maestro.mobile.dev' | bash"
