#!/bin/bash
# Run multi-user friend tests on two iOS simulators in parallel
#
# Prerequisites:
# 1. Two iOS simulators running with ButtonLog app installed
# 2. User 1 authenticated on first simulator
# 3. User 2 authenticated on second simulator
#
# Usage: ./scripts/run-multi-user-ios.sh

set -e

# Add Maestro to PATH
export PATH="$PATH:$HOME/.maestro/bin"

echo ""
echo "========================================"
echo "iOS Multi-User Friend Tests"
echo "========================================"
echo ""

# Get list of booted simulators
SIMULATORS=$(xcrun simctl list devices | grep "Booted" | sed 's/.*(\([A-F0-9-]*\)).*/\1/')
SIM_COUNT=$(echo "$SIMULATORS" | wc -l | tr -d ' ')

if [ "$SIM_COUNT" -lt 2 ]; then
    echo "ERROR: Need at least 2 booted iOS simulators!"
    echo ""
    echo "Current booted simulators: $SIM_COUNT"
    echo ""
    echo "To boot simulators:"
    echo "  xcrun simctl boot 'iPhone 15 Pro'"
    echo "  xcrun simctl boot 'iPhone 15'"
    echo ""
    echo "Or open Simulator app and start two devices."
    exit 1
fi

SIM1=$(echo "$SIMULATORS" | head -1)
SIM2=$(echo "$SIMULATORS" | tail -1)

echo "Using simulators:"
echo "  User 1: $SIM1"
echo "  User 2: $SIM2"
echo ""

# Run tests sequentially (iOS limitation: only one gesture at a time across simulators)
echo "Running User 1 tests on $SIM1..."
maestro test --device "$SIM1" ios/friends-multi-user1.yaml
STATUS1=$?

echo ""
echo "Running User 2 tests on $SIM2..."
maestro test --device "$SIM2" ios/friends-multi-user2.yaml
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
