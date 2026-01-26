#!/bin/bash

# ButtonLog iOS Integration Test Runner
#
# Usage:
#   ./scripts/run-integration-tests.sh [environment] [test-suite]
#
# Examples:
#   ./scripts/run-integration-tests.sh local          # Run all integration tests against local
#   ./scripts/run-integration-tests.sh staging        # Run all integration tests against staging
#   ./scripts/run-integration-tests.sh local auth     # Run only auth tests against local
#   ./scripts/run-integration-tests.sh staging button # Run only button tests against staging
#
# Environment:
#   local   - http://localhost:14015/api (default)
#   staging - https://staging.buttonlog.com/api
#   prod    - https://buttonlog.com/api (limited tests only)
#
# Test Suites:
#   all     - Run all integration tests (default)
#   auth    - Run AuthIntegrationTests
#   button  - Run ButtonIntegrationTests
#   friends - Run FriendsIntegrationTests

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Parse arguments
ENVIRONMENT=${1:-local}
TEST_SUITE=${2:-all}

# Set API base URL based on environment
case $ENVIRONMENT in
    local)
        export TEST_API_BASE_URL="http://localhost:14015/api"
        echo -e "${GREEN}Running against local development server${NC}"
        ;;
    staging)
        export TEST_API_BASE_URL="https://staging.buttonlog.com/api"
        echo -e "${YELLOW}Running against staging server${NC}"
        ;;
    prod|production)
        export TEST_API_BASE_URL="https://buttonlog.com/api"
        echo -e "${RED}Running against PRODUCTION server (limited tests only!)${NC}"
        ;;
    *)
        echo -e "${RED}Unknown environment: $ENVIRONMENT${NC}"
        echo "Valid environments: local, staging, prod"
        exit 1
        ;;
esac

echo "API Base URL: $TEST_API_BASE_URL"
echo ""

# Build test filter based on suite
case $TEST_SUITE in
    all)
        TEST_FILTER="ButtonLogTests"
        echo "Running all integration tests..."
        ;;
    auth)
        TEST_FILTER="ButtonLogTests/AuthIntegrationTests"
        echo "Running Auth integration tests..."
        ;;
    button|buttons)
        TEST_FILTER="ButtonLogTests/ButtonIntegrationTests"
        echo "Running Button integration tests..."
        ;;
    friends|friend|social)
        TEST_FILTER="ButtonLogTests/FriendsIntegrationTests"
        echo "Running Friends integration tests..."
        ;;
    *)
        echo -e "${RED}Unknown test suite: $TEST_SUITE${NC}"
        echo "Valid test suites: all, auth, button, friends"
        exit 1
        ;;
esac

echo ""

# Check if local server is running (for local environment)
if [ "$ENVIRONMENT" = "local" ]; then
    if ! curl -s http://localhost:14015/api/config > /dev/null 2>&1; then
        echo -e "${RED}Warning: Local server does not appear to be running at localhost:14015${NC}"
        echo "Please start the backend server first:"
        echo "  cd backend && source .env && mix phx.server"
        echo ""
        read -p "Continue anyway? (y/n) " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        echo -e "${GREEN}Local server is running${NC}"
    fi
fi

echo ""

# Change to iPhone directory
cd "$(dirname "$0")/.."

# Run the tests using xcodebuild
echo "Running tests..."
echo ""

# Detect the correct destination
DESTINATION="platform=iOS Simulator,name=iPhone 16,OS=latest"

xcodebuild test \
    -project ButtonLog.xcodeproj \
    -scheme ButtonLog \
    -destination "$DESTINATION" \
    -only-testing:"$TEST_FILTER" \
    TEST_API_BASE_URL="$TEST_API_BASE_URL" \
    2>&1 | xcpretty || {
        # If xcpretty is not installed, fall back to raw output
        xcodebuild test \
            -project ButtonLog.xcodeproj \
            -scheme ButtonLog \
            -destination "$DESTINATION" \
            -only-testing:"$TEST_FILTER" \
            TEST_API_BASE_URL="$TEST_API_BASE_URL"
    }

echo ""
echo -e "${GREEN}Integration tests completed!${NC}"
