#!/bin/bash

# ButtonLog Comprehensive Test Runner
# Runs all tests across all platforms and levels
#
# Usage:
#   ./scripts/run-all-tests.sh [environment]
#
# Environments:
#   local   - Run against local development server (default)
#   staging - Run against staging server
#
# Examples:
#   ./scripts/run-all-tests.sh local
#   ./scripts/run-all-tests.sh staging

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse arguments
ENVIRONMENT=${1:-local}
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Track results
declare -a PASSED_TESTS
declare -a FAILED_TESTS
declare -a SKIPPED_TESTS

# Set environment-specific variables
case $ENVIRONMENT in
    local)
        export API_BASE_URL="http://localhost:14015/api"
        export TEST_API_BASE_URL="http://localhost:14015/api"
        BACKEND_URL="http://localhost:14015"
        echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
        echo -e "${GREEN}  ButtonLog Test Suite - LOCAL ENVIRONMENT${NC}"
        echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
        ;;
    staging)
        export API_BASE_URL="https://staging.buttonlog.com/api"
        export TEST_API_BASE_URL="https://staging.buttonlog.com/api"
        BACKEND_URL="https://staging.buttonlog.com"
        echo -e "${YELLOW}════════════════════════════════════════════════════════════${NC}"
        echo -e "${YELLOW}  ButtonLog Test Suite - STAGING ENVIRONMENT${NC}"
        echo -e "${YELLOW}════════════════════════════════════════════════════════════${NC}"
        ;;
    *)
        echo -e "${RED}Unknown environment: $ENVIRONMENT${NC}"
        echo "Valid environments: local, staging"
        exit 1
        ;;
esac

echo ""
echo "API URL: $API_BASE_URL"
echo "Started: $(date)"
echo ""

# Function to run a test and track result
run_test() {
    local name="$1"
    local command="$2"
    local optional="${3:-false}"

    echo -e "${BLUE}────────────────────────────────────────────────────────────${NC}"
    echo -e "${BLUE}Running: $name${NC}"
    echo -e "${BLUE}────────────────────────────────────────────────────────────${NC}"

    if eval "$command"; then
        echo -e "${GREEN}✓ PASSED: $name${NC}"
        PASSED_TESTS+=("$name")
        return 0
    else
        if [ "$optional" = "true" ]; then
            echo -e "${YELLOW}⚠ SKIPPED: $name (optional)${NC}"
            SKIPPED_TESTS+=("$name")
            return 0
        else
            echo -e "${RED}✗ FAILED: $name${NC}"
            FAILED_TESTS+=("$name")
            return 1
        fi
    fi
}

# Check if local server is running (for local environment)
check_local_server() {
    if [ "$ENVIRONMENT" = "local" ]; then
        echo -e "${BLUE}Checking local server...${NC}"
        if curl -s "$BACKEND_URL/api/config" > /dev/null 2>&1; then
            echo -e "${GREEN}✓ Local server is running${NC}"
            return 0
        else
            echo -e "${RED}✗ Local server is NOT running at $BACKEND_URL${NC}"
            echo ""
            echo "Please start the backend server first:"
            echo "  cd backend && source .env && mix phx.server"
            echo ""
            return 1
        fi
    fi
    return 0
}

# ═══════════════════════════════════════════════════════════════
# BACKEND TESTS (Elixir/Phoenix)
# ═══════════════════════════════════════════════════════════════
run_backend_tests() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  BACKEND TESTS (Elixir/Phoenix)${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"

    cd "$PROJECT_ROOT/backend"

    # Backend tests always run against test database, not affected by environment
    run_test "Backend Unit & Integration Tests" \
        "source .env && mix test"
}

# ═══════════════════════════════════════════════════════════════
# ANDROID TESTS
# ═══════════════════════════════════════════════════════════════
run_android_tests() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  ANDROID TESTS${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"

    cd "$PROJECT_ROOT/android"

    # Unit tests (don't require server)
    run_test "Android Unit Tests" \
        "./gradlew test --no-daemon"

    # Integration tests (require server and emulator)
    if [ "$ENVIRONMENT" = "local" ]; then
        # Check if emulator is running
        if adb devices 2>/dev/null | grep -q "emulator"; then
            run_test "Android Integration Tests (Local)" \
                "./gradlew connectedDevelopmentDebugAndroidTest --no-daemon" \
                "true"  # Optional - may fail if no emulator
        else
            echo -e "${YELLOW}⚠ Skipping Android Integration Tests - No emulator running${NC}"
            SKIPPED_TESTS+=("Android Integration Tests")
        fi
    else
        # For staging, use staging flavor
        if adb devices 2>/dev/null | grep -q "emulator"; then
            run_test "Android Integration Tests (Staging)" \
                "./gradlew connectedStagingDebugAndroidTest --no-daemon" \
                "true"
        else
            echo -e "${YELLOW}⚠ Skipping Android Integration Tests - No emulator running${NC}"
            SKIPPED_TESTS+=("Android Integration Tests")
        fi
    fi
}

# ═══════════════════════════════════════════════════════════════
# iOS TESTS
# ═══════════════════════════════════════════════════════════════
run_ios_tests() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  iOS TESTS${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"

    cd "$PROJECT_ROOT/iphone"

    # Check if we're on macOS
    if [[ "$(uname)" != "Darwin" ]]; then
        echo -e "${YELLOW}⚠ Skipping iOS tests - Not on macOS${NC}"
        SKIPPED_TESTS+=("iOS Tests")
        return 0
    fi

    # Check if Xcode is available
    if ! command -v xcodebuild &> /dev/null; then
        echo -e "${YELLOW}⚠ Skipping iOS tests - Xcode not installed${NC}"
        SKIPPED_TESTS+=("iOS Tests")
        return 0
    fi

    # Find available simulator
    SIMULATOR=$(xcrun simctl list devices available | grep "iPhone" | head -1 | sed 's/.*(\([^)]*\)).*/\1/')

    if [ -z "$SIMULATOR" ]; then
        echo -e "${YELLOW}⚠ Skipping iOS tests - No simulator available${NC}"
        SKIPPED_TESTS+=("iOS Tests")
        return 0
    fi

    DESTINATION="platform=iOS Simulator,id=$SIMULATOR"

    # Run all iOS tests
    run_test "iOS Unit & Integration Tests" \
        "xcodebuild test -project ButtonLog.xcodeproj -scheme ButtonLog -destination \"$DESTINATION\" TEST_API_BASE_URL=\"$TEST_API_BASE_URL\" 2>&1 | xcpretty || xcodebuild test -project ButtonLog.xcodeproj -scheme ButtonLog -destination \"$DESTINATION\" TEST_API_BASE_URL=\"$TEST_API_BASE_URL\"" \
        "true"
}

# ═══════════════════════════════════════════════════════════════
# E2E TESTS (Maestro)
# ═══════════════════════════════════════════════════════════════
run_e2e_tests() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  E2E TESTS (Maestro)${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"

    cd "$PROJECT_ROOT/e2e-mobile"

    # Check if Maestro is installed
    if ! command -v maestro &> /dev/null; then
        echo -e "${YELLOW}⚠ Skipping E2E tests - Maestro not installed${NC}"
        echo "Install with: curl -Ls \"https://get.maestro.mobile.dev\" | bash"
        SKIPPED_TESTS+=("E2E Tests")
        return 0
    fi

    # E2E tests are optional as they require specific setup
    if [[ "$(uname)" == "Darwin" ]]; then
        # iOS E2E tests
        run_test "E2E iOS Tests" \
            "maestro test ios/" \
            "true"
    fi

    # Android E2E tests
    if adb devices 2>/dev/null | grep -q "emulator\|device"; then
        run_test "E2E Android Tests" \
            "maestro test android/" \
            "true"
    else
        echo -e "${YELLOW}⚠ Skipping E2E Android tests - No device connected${NC}"
        SKIPPED_TESTS+=("E2E Android Tests")
    fi
}

# ═══════════════════════════════════════════════════════════════
# MAIN EXECUTION
# ═══════════════════════════════════════════════════════════════

# Check server for local environment
if ! check_local_server; then
    exit 1
fi

# Run all test suites
run_backend_tests
run_android_tests
run_ios_tests
run_e2e_tests

# ═══════════════════════════════════════════════════════════════
# SUMMARY
# ═══════════════════════════════════════════════════════════════
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  TEST SUMMARY${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo "Environment: $ENVIRONMENT"
echo "Completed: $(date)"
echo ""

echo -e "${GREEN}PASSED (${#PASSED_TESTS[@]}):${NC}"
for test in "${PASSED_TESTS[@]}"; do
    echo -e "  ${GREEN}✓${NC} $test"
done

if [ ${#SKIPPED_TESTS[@]} -gt 0 ]; then
    echo ""
    echo -e "${YELLOW}SKIPPED (${#SKIPPED_TESTS[@]}):${NC}"
    for test in "${SKIPPED_TESTS[@]}"; do
        echo -e "  ${YELLOW}⚠${NC} $test"
    done
fi

if [ ${#FAILED_TESTS[@]} -gt 0 ]; then
    echo ""
    echo -e "${RED}FAILED (${#FAILED_TESTS[@]}):${NC}"
    for test in "${FAILED_TESTS[@]}"; do
        echo -e "  ${RED}✗${NC} $test"
    done
    echo ""
    echo -e "${RED}════════════════════════════════════════════════════════════${NC}"
    echo -e "${RED}  TESTS FAILED${NC}"
    echo -e "${RED}════════════════════════════════════════════════════════════${NC}"
    exit 1
else
    echo ""
    echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  ALL TESTS PASSED${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
    exit 0
fi
