#!/bin/bash

# Usage: ./send_message.sh <recipient> <message>
# recipient can be:
#   - phone number (e.g., +15551234567)
#   - email address (e.g., user@example.com)
#   - contact name (e.g., "John Smith")

RECIPIENT="$1"
MESSAGE="$2"

if [ -z "$RECIPIENT" ] || [ -z "$MESSAGE" ]; then
    echo "Usage: $0 <recipient> <message>"
    echo "  recipient: phone number, email, or contact name"
    echo "  message: the message to send"
    exit 1
fi

# Function to check if recipient looks like a phone number or email
is_phone_or_email() {
    local input="$1"
    # Check if it contains @ (email)
    if [[ "$input" == *"@"* ]]; then
        return 0
    fi
    # Check if it starts with + (international phone)
    if [[ "$input" == "+"* ]]; then
        return 0
    fi
    # Check if it's mostly digits (phone number) - at least 7 digits
    local digits_only=$(echo "$input" | tr -cd '0-9')
    if [[ ${#digits_only} -ge 7 ]]; then
        return 0
    fi
    return 1
}

# If recipient doesn't look like a phone/email, try to look up in Contacts
if ! is_phone_or_email "$RECIPIENT"; then
    echo "Looking up contact: $RECIPIENT"

    # Try to find phone number or email from Contacts
    CONTACT_INFO=$(osascript <<EOF
tell application "Contacts"
    set matchingPeople to (every person whose name contains "$RECIPIENT")
    if (count of matchingPeople) > 0 then
        set thePerson to item 1 of matchingPeople

        -- Try to get iMessage-capable identifier (phone or email)
        set thePhones to phones of thePerson
        if (count of thePhones) > 0 then
            set thePhone to value of item 1 of thePhones
            return thePhone
        end if

        -- Fall back to email
        set theEmails to emails of thePerson
        if (count of theEmails) > 0 then
            set theEmail to value of item 1 of theEmails
            return theEmail
        end if
    end if
    return ""
end tell
EOF
)

    if [ -z "$CONTACT_INFO" ]; then
        echo "Error: Could not find contact '$RECIPIENT'"
        exit 1
    fi

    echo "Found contact info: $CONTACT_INFO"
    RECIPIENT="$CONTACT_INFO"
fi

# Escape quotes in message for AppleScript
ESCAPED_MESSAGE=$(echo "$MESSAGE" | sed 's/"/\\"/g')

# Send the message via iMessage
osascript <<EOF
tell application "Messages"
    set targetService to 1st account whose service type = iMessage
    set targetBuddy to participant "$RECIPIENT" of targetService
    send "$ESCAPED_MESSAGE" to targetBuddy
end tell
EOF

if [ $? -eq 0 ]; then
    echo "Message sent successfully to $RECIPIENT"
else
    echo "Failed to send message"
    exit 1
fi
