#!/bin/bash
# Validate friends API response
# Returns JSON with friend count and pending request count

API_BASE_URL="${API_BASE_URL:-https://staging.buttonlog.com/api}"
AUTH_TOKEN="${AUTH_TOKEN}"

if [ -z "$AUTH_TOKEN" ]; then
    echo '{"error": "AUTH_TOKEN not set"}'
    exit 1
fi

# Get friends from API
response=$(curl -s -X GET "$API_BASE_URL/friends" \
    -H "Authorization: Bearer $AUTH_TOKEN" \
    -H "Content-Type: application/json")

# Check if request succeeded
if [ $? -ne 0 ]; then
    echo '{"error": "API request failed"}'
    exit 1
fi

# Parse response
success=$(echo "$response" | jq -r '.success')
if [ "$success" != "true" ]; then
    error=$(echo "$response" | jq -r '.error.message // "Unknown error"')
    echo "{\"error\": \"$error\"}"
    exit 1
fi

# Get counts
totalCount=$(echo "$response" | jq '.data | length')
acceptedCount=$(echo "$response" | jq '[.data[] | select(.status == "accepted")] | length')
pendingCount=$(echo "$response" | jq '[.data[] | select(.status == "pending")] | length')

# Return JSON
echo "{\"total\": $totalCount, \"accepted\": $acceptedCount, \"pending\": $pendingCount}"
