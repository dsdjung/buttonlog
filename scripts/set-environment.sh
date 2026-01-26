#!/bin/bash

# ButtonLog Environment Switcher
# Usage: ./scripts/set-environment.sh [local|staging|production]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

get_urls() {
    local env=$1
    case $env in
        local)
            IOS_API_URL="http://localhost:14015/api"
            IOS_WEB_URL="http://localhost:14015"
            ANDROID_API_URL="http://10.0.2.2:14015/api/"
            ANDROID_WEB_URL="http://10.0.2.2:14015"
            ;;
        staging)
            IOS_API_URL="https://staging.buttonlog.com/api"
            IOS_WEB_URL="https://staging.buttonlog.com"
            ANDROID_API_URL="https://staging.buttonlog.com/api/"
            ANDROID_WEB_URL="https://staging.buttonlog.com"
            ;;
        production)
            IOS_API_URL="https://buttonlog.com/api"
            IOS_WEB_URL="https://buttonlog.com"
            ANDROID_API_URL="https://buttonlog.com/api/"
            ANDROID_WEB_URL="https://buttonlog.com"
            ;;
    esac
}

usage() {
    echo "Usage: $0 [local|staging|production]"
    echo ""
    echo "Environments:"
    echo "  local       - Point to localhost:14015 (local Phoenix server)"
    echo "  staging     - Point to staging.buttonlog.com"
    echo "  production  - Point to buttonlog.com"
    echo ""
    echo "Current environment:"
    show_current
    exit 1
}

show_current() {
    echo ""
    # Check iOS
    if [ -f "$PROJECT_ROOT/iphone/ButtonLog/Configuration/Environment.swift" ]; then
        IOS_URL=$(grep -A3 "case .development:" "$PROJECT_ROOT/iphone/ButtonLog/Configuration/Environment.swift" | grep "return" | head -1 | sed 's/.*return "\(.*\)"/\1/')
        if echo "$IOS_URL" | grep -q "localhost"; then
            echo -e "  iOS:     ${YELLOW}local${NC} ($IOS_URL)"
        elif echo "$IOS_URL" | grep -q "staging"; then
            echo -e "  iOS:     ${YELLOW}staging${NC} ($IOS_URL)"
        else
            echo -e "  iOS:     ${YELLOW}production${NC} ($IOS_URL)"
        fi
    fi

    # Check Android
    if [ -f "$PROJECT_ROOT/android/app/build.gradle.kts" ]; then
        ANDROID_URL=$(grep -A7 'create("development")' "$PROJECT_ROOT/android/app/build.gradle.kts" | grep "API_BASE_URL" | head -1 | sed 's/.*"\\"\(.*\)\\"".*/\1/')
        if echo "$ANDROID_URL" | grep -q "10.0.2.2"; then
            echo -e "  Android: ${YELLOW}local${NC} ($ANDROID_URL)"
        elif echo "$ANDROID_URL" | grep -q "staging"; then
            echo -e "  Android: ${YELLOW}staging${NC} ($ANDROID_URL)"
        else
            echo -e "  Android: ${YELLOW}production${NC} ($ANDROID_URL)"
        fi
    fi
    echo ""
}

update_ios() {
    local env=$1
    get_urls "$env"

    local ios_file="$PROJECT_ROOT/iphone/ButtonLog/Configuration/Environment.swift"

    if [ ! -f "$ios_file" ]; then
        echo -e "${RED}Error: iOS Environment.swift not found${NC}"
        return 1
    fi

    # Create temp file with new content
    local temp_file=$(mktemp)

    # Process the file line by line
    local in_api_block=0
    local in_web_block=0
    local skip_until_staging=0

    while IFS= read -r line; do
        # Detect start of apiBaseURL function
        if echo "$line" | grep -q "/// The base URL for API requests"; then
            in_api_block=1
        fi

        # Detect start of webBaseURL function
        if echo "$line" | grep -q "/// The base URL for web/OAuth"; then
            in_web_block=1
        fi

        # Handle development case in API block
        if [ $in_api_block -eq 1 ] && echo "$line" | grep -q "case .development:"; then
            echo "$line" >> "$temp_file"
            echo "            // Set by scripts/set-environment.sh - currently: $env" >> "$temp_file"
            echo "            return \"$IOS_API_URL\"" >> "$temp_file"
            skip_until_staging=1
            continue
        fi

        # Handle development case in web block
        if [ $in_web_block -eq 1 ] && [ $in_api_block -eq 0 ] && echo "$line" | grep -q "case .development:"; then
            echo "$line" >> "$temp_file"
            echo "            // Set by scripts/set-environment.sh - currently: $env" >> "$temp_file"
            echo "            return \"$IOS_WEB_URL\"" >> "$temp_file"
            skip_until_staging=1
            continue
        fi

        # Skip lines until we hit staging case
        if [ $skip_until_staging -eq 1 ]; then
            if echo "$line" | grep -q "case .staging:"; then
                skip_until_staging=0
                in_api_block=0
                in_web_block=0
            else
                continue
            fi
        fi

        # Detect end of functions
        if echo "$line" | grep -q "/// Whether to enable debug logging"; then
            in_api_block=0
            in_web_block=0
        fi

        echo "$line" >> "$temp_file"
    done < "$ios_file"

    mv "$temp_file" "$ios_file"
    echo -e "${GREEN}✓ iOS updated to $env${NC}"
}

update_android() {
    local env=$1
    get_urls "$env"

    local android_file="$PROJECT_ROOT/android/app/build.gradle.kts"

    if [ ! -f "$android_file" ]; then
        echo -e "${RED}Error: Android build.gradle.kts not found${NC}"
        return 1
    fi

    # Create temp file
    local temp_file=$(mktemp)

    local in_dev_flavor=0
    local brace_count=0

    while IFS= read -r line; do
        # Detect start of development flavor
        if echo "$line" | grep -q 'create("development")'; then
            in_dev_flavor=1
            brace_count=0
        fi

        if [ $in_dev_flavor -eq 1 ]; then
            # Count braces
            opens=$(echo "$line" | grep -o "{" | wc -l)
            closes=$(echo "$line" | grep -o "}" | wc -l)
            brace_count=$((brace_count + opens - closes))

            # Replace API_BASE_URL line
            if echo "$line" | grep -q "API_BASE_URL"; then
                echo "            // Set by scripts/set-environment.sh - currently: $env" >> "$temp_file"
                echo "            buildConfigField(\"String\", \"API_BASE_URL\", \"\\\"$ANDROID_API_URL\\\"\")" >> "$temp_file"
                continue
            fi

            # Replace WEB_BASE_URL line
            if echo "$line" | grep -q "WEB_BASE_URL"; then
                echo "            buildConfigField(\"String\", \"WEB_BASE_URL\", \"\\\"$ANDROID_WEB_URL\\\"\")" >> "$temp_file"
                continue
            fi

            # Skip old comment lines
            if echo "$line" | grep -q "// Set by scripts/set-environment.sh"; then
                continue
            fi
            if echo "$line" | grep -q "// API URL for local development"; then
                continue
            fi

            # Check if we've exited the development block
            if [ $brace_count -eq 0 ] && [ $opens -eq 0 ] && [ $closes -gt 0 ]; then
                in_dev_flavor=0
            fi
        fi

        echo "$line" >> "$temp_file"
    done < "$android_file"

    mv "$temp_file" "$android_file"
    echo -e "${GREEN}✓ Android updated to $env${NC}"
}

# Main
if [ $# -eq 0 ]; then
    usage
fi

ENV=$1

case $ENV in
    local|staging|production)
        echo -e "${GREEN}Switching to $ENV environment...${NC}"
        echo ""
        update_ios "$ENV"
        update_android "$ENV"
        echo ""
        echo -e "${GREEN}Done! Environment set to: $ENV${NC}"
        show_current
        echo ""
        echo "Note: Rebuild the apps for changes to take effect."
        echo "  iOS:     Clean build (Cmd+Shift+K) and rebuild"
        echo "  Android: ./gradlew clean assembleDevelopmentDebug"
        ;;
    *)
        echo -e "${RED}Error: Invalid environment '$ENV'${NC}"
        usage
        ;;
esac
