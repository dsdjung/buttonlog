#!/bin/bash

# ButtonLog Android Integration Test Runner
#
# Usage:
#   ./scripts/run-integration-tests.sh [environment] [test_class]
#
# Environments:
#   local     - Run against local dev server (http://10.0.2.2:4000/api/)
#   staging   - Run against staging server (default API_BASE_URL)
#   production - Run sanity tests against production (most tests skipped)
#
# Examples:
#   ./scripts/run-integration-tests.sh local                    # All tests against local
#   ./scripts/run-integration-tests.sh staging                  # All tests against staging
#   ./scripts/run-integration-tests.sh local auth               # Auth tests only against local
#   ./scripts/run-integration-tests.sh staging button           # Button tests only against staging
#   ./scripts/run-integration-tests.sh production               # Sanity tests against production

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANDROID_DIR="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
ENVIRONMENT="${1:-staging}"
TEST_FILTER="${2:-}"

# Map environment to flavor and API URL
case "$ENVIRONMENT" in
    local|dev)
        FLAVOR="development"
        API_URL="http://10.0.2.2:4000/api/"
        echo -e "${BLUE}Running against LOCAL development server${NC}"
        echo -e "${YELLOW}Make sure your Phoenix server is running on localhost:4000${NC}"
        ;;
    staging)
        FLAVOR="staging"
        API_URL="" # Use default from BuildConfig
        echo -e "${BLUE}Running against STAGING server${NC}"
        ;;
    production|prod)
        FLAVOR="production"
        API_URL="" # Use default from BuildConfig
        echo -e "${RED}⚠️  Running against PRODUCTION - most tests will be skipped${NC}"
        ;;
    *)
        echo -e "${RED}Unknown environment: $ENVIRONMENT${NC}"
        echo "Usage: $0 [local|staging|production] [auth|button|friends|all]"
        exit 1
        ;;
esac

# Build the test class filter
TEST_CLASS=""
case "$TEST_FILTER" in
    auth)
        TEST_CLASS="com.buttonlog.app.integration.AuthIntegrationTest"
        echo -e "${BLUE}Running: Authentication integration tests${NC}"
        ;;
    button|buttons)
        TEST_CLASS="com.buttonlog.app.integration.ButtonIntegrationTest"
        echo -e "${BLUE}Running: Button integration tests${NC}"
        ;;
    friends|friend|social)
        TEST_CLASS="com.buttonlog.app.integration.FriendsIntegrationTest"
        echo -e "${BLUE}Running: Friends integration tests${NC}"
        ;;
    all|"")
        TEST_CLASS=""
        echo -e "${BLUE}Running: ALL integration tests${NC}"
        ;;
    *)
        # Assume it's a custom class name
        TEST_CLASS="com.buttonlog.app.integration.${TEST_FILTER}"
        echo -e "${BLUE}Running: ${TEST_FILTER}${NC}"
        ;;
esac

echo ""
echo "Environment: $ENVIRONMENT"
echo "Flavor: $FLAVOR"
if [ -n "$API_URL" ]; then
    echo "API URL: $API_URL"
else
    echo "API URL: (using BuildConfig default)"
fi
echo ""

# Change to android directory
cd "$ANDROID_DIR"

# Build the gradle command
GRADLE_CMD="./gradlew connected${FLAVOR^}DebugAndroidTest"

# Add test class filter if specified
if [ -n "$TEST_CLASS" ]; then
    GRADLE_CMD="$GRADLE_CMD -Pandroid.testInstrumentationRunnerArguments.class=$TEST_CLASS"
fi

# Add API URL override for local development
if [ -n "$API_URL" ]; then
    GRADLE_CMD="$GRADLE_CMD -Dtest.api.baseUrl=$API_URL"
fi

# Add verbose logging
GRADLE_CMD="$GRADLE_CMD --info"

echo -e "${GREEN}Executing: $GRADLE_CMD${NC}"
echo ""

# Run the tests
eval $GRADLE_CMD

# Check result
if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ Integration tests PASSED${NC}"
else
    echo ""
    echo -e "${RED}❌ Integration tests FAILED${NC}"
    exit 1
fi
