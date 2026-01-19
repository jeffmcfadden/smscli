#!/bin/bash

# Send a message via iMessage
# Usage: ./send_message.sh <recipient> <message>
# recipient should be a phone number, email, or group chat name
# (use contact_lookup.sh first to resolve contact names)

RECIPIENT="$1"
MESSAGE="$2"

if [ -z "$RECIPIENT" ] || [ -z "$MESSAGE" ]; then
    echo "Usage: $0 <recipient> <message>" >&2
    echo "  recipient: phone number, email, or group chat name" >&2
    exit 1
fi

# Escape quotes in message for AppleScript
ESCAPED_MESSAGE=$(echo "$MESSAGE" | sed 's/"/\\"/g')

# Check if recipient is a group chat
GROUP_CHAT=$(osascript <<EOF 2>/dev/null
tell application "Messages"
    try
        set targetChat to (first chat whose name is "$RECIPIENT")
        return name of targetChat
    on error
        return ""
    end try
end tell
EOF
)

if [ -n "$GROUP_CHAT" ]; then
    # Send to group chat
    osascript <<EOF
tell application "Messages"
    set targetChat to (first chat whose name is "$RECIPIENT")
    send "$ESCAPED_MESSAGE" to targetChat
end tell
EOF
    RESULT=$?
    if [ $RESULT -eq 0 ]; then
        logger -t "sms" "Sent message to group chat '$RECIPIENT' (${#MESSAGE} chars)"
    else
        logger -t "sms" "FAILED to send message to group chat '$RECIPIENT'"
    fi
    exit $RESULT
else
    # Send to individual via iMessage
    osascript <<EOF
tell application "Messages"
    set targetService to 1st account whose service type = iMessage
    set targetBuddy to participant "$RECIPIENT" of targetService
    send "$ESCAPED_MESSAGE" to targetBuddy
end tell
EOF
    RESULT=$?
    if [ $RESULT -eq 0 ]; then
        logger -t "sms" "Sent message to '$RECIPIENT' (${#MESSAGE} chars)"
    else
        logger -t "sms" "FAILED to send message to '$RECIPIENT'"
    fi
    exit $RESULT
fi
