#!/bin/bash
# Validate buttons API response
# Returns the button count from the API

API_BASE_URL="${API_BASE_URL:-https://staging.buttonlog.com/api}"
AUTH_TOKEN="${AUTH_TOKEN}"

if [ -z "$AUTH_TOKEN" ]; then
    echo "ERROR: AUTH_TOKEN not set" >&2
    exit 1
fi

# Get buttons from API
response=$(curl -s -X GET "$API_BASE_URL/buttons" \
    -H "Authorization: Bearer $AUTH_TOKEN" \
    -H "Content-Type: application/json")

# Check if request succeeded
if [ $? -ne 0 ]; then
    echo "ERROR: API request failed" >&2
    exit 1
fi

# Parse response
success=$(echo "$response" | jq -r '.success')
if [ "$success" != "true" ]; then
    error=$(echo "$response" | jq -r '.error.message // "Unknown error"')
    echo "ERROR: API returned error: $error" >&2
    exit 1
fi

# Get button count
count=$(echo "$response" | jq '.data | length')
echo "$count"
