#!/bin/bash
# Validate that a button was created
# Returns "true" if button exists, "false" otherwise

API_BASE_URL="${API_BASE_URL:-https://staging.buttonlog.com/api}"
AUTH_TOKEN="${AUTH_TOKEN}"
BUTTON_NAME="${BUTTON_NAME}"

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
    echo "false"
    exit 0
fi

# Check if button with name exists
if [ -n "$BUTTON_NAME" ]; then
    exists=$(echo "$response" | jq --arg name "$BUTTON_NAME" '[.data[] | select(.name | contains($name))] | length > 0')
    echo "$exists"
else
    # Just check if there are any buttons
    count=$(echo "$response" | jq '.data | length')
    if [ "$count" -gt 0 ]; then
        echo "true"
    else
        echo "false"
    fi
fi
