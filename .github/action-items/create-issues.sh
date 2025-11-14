#!/bin/bash

set -e


# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo "Error: Not authenticated with GitHub CLI."
    echo "Run: gh auth login"
    exit 1
fi

# Check if JSON file is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <json-file>"
    echo "Example: $0 2025-10-31-meeting-action-items.json"
    exit 1
fi

JSON_FILE="$1"

# Check if file exists
if [ ! -f "$JSON_FILE" ]; then
    echo "Error: File '$JSON_FILE' not found."
    exit 1
fi

# Repository (update if needed)
REPO="OHDSI/GIS"

echo "Creating issues in repository: $REPO"
echo "Reading from: $JSON_FILE"
echo ""

# Counter for created issues
CREATED=0
SKIPPED=0

# Read JSON array length
ISSUE_COUNT=$(jq '. | length' "$JSON_FILE")

echo "Found $ISSUE_COUNT action items to process"
echo ""

# Iterate through each issue in the JSON array
for i in $(seq 0 $((ISSUE_COUNT - 1))); do
    # Extract issue data
    TITLE=$(jq -r ".[$i].title" "$JSON_FILE")
    BODY=$(jq -r ".[$i].body" "$JSON_FILE")
    LABELS=$(jq -r ".[$i].labels | join(\",\")" "$JSON_FILE")
    ASSIGNEES=$(jq -r ".[$i].assignees | join(\",\")" "$JSON_FILE")

    echo "[$((i + 1))/$ISSUE_COUNT] Processing: $TITLE"

    # Build gh issue create command
    CMD="gh issue create --repo $REPO --title \"$TITLE\" --body \"$BODY\""

    # Add labels if present
    if [ "$LABELS" != "" ] && [ "$LABELS" != "null" ]; then
        CMD="$CMD --label \"$LABELS\""
    fi

    # Add assignees if present
    if [ "$ASSIGNEES" != "" ] && [ "$ASSIGNEES" != "null" ]; then
        CMD="$CMD --assignee \"$ASSIGNEES\""
    fi

    # Execute command
    if eval "$CMD"; then
        echo "Created successfully!"
        ((CREATED++))
    else
        echo "Failed to create..."
        ((SKIPPED++))
    fi

    echo ""

    # Small delay to avoid rate limiting
    sleep 1
done

echo "Summary:"
echo "  Created: $CREATED"
echo "  Skipped: $SKIPPED"
echo "  Total:   $ISSUE_COUNT"
echo ""
echo "Done!"
