#!/bin/bash
# Validate that a button click was recorded
# Returns "true" if recent click exists, "false" otherwise

API_BASE_URL="${API_BASE_URL:-https://staging.buttonlog.com/api}"
AUTH_TOKEN="${AUTH_TOKEN}"
BUTTON_ID="${BUTTON_ID}"

if [ -z "$AUTH_TOKEN" ]; then
    echo "ERROR: AUTH_TOKEN not set" >&2
    exit 1
fi

# If we have a specific button ID, check its history
if [ -n "$BUTTON_ID" ]; then
    response=$(curl -s -X GET "$API_BASE_URL/buttons/$BUTTON_ID/history" \
        -H "Authorization: Bearer $AUTH_TOKEN" \
        -H "Content-Type: application/json")
else
    # Get all buttons and check the most recent one
    response=$(curl -s -X GET "$API_BASE_URL/buttons" \
        -H "Authorization: Bearer $AUTH_TOKEN" \
        -H "Content-Type: application/json")
fi

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

if [ -n "$BUTTON_ID" ]; then
    # Check history for clicks
    clickCount=$(echo "$response" | jq '.data | length')
    if [ "$clickCount" -gt 0 ]; then
        echo "true"
    else
        echo "false"
    fi
else
    # Check if any button has clicks
    hasClicks=$(echo "$response" | jq '[.data[] | select(.click_count > 0)] | length > 0')
    echo "$hasClicks"
fi
