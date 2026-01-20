#!/bin/bash

# Look up a contact by name and return their phone number or email
# Usage: ./contact_lookup.sh <name>
# Returns: phone number or email (first match), or empty if not found

NAME="$1"

if [ -z "$NAME" ]; then
    echo "Usage: $0 <name>" >&2
    exit 1
fi

# Check if input already looks like a phone number or email
# If so, just return it as-is
if [[ "$NAME" == *"@"* ]] || [[ "$NAME" == "+"* ]]; then
    echo "$NAME"
    exit 0
fi

# Check if it's mostly digits (phone number)
digits_only=$(echo "$NAME" | tr -cd '0-9')
if [[ ${#digits_only} -ge 7 ]]; then
    echo "$NAME"
    exit 0
fi

# Look up in Contacts
CONTACT_INFO=$(osascript <<EOF
tell application "Contacts"
    launch
    delay 0.5
    set matchingPeople to (every person whose name contains "$NAME")
    if (count of matchingPeople) > 0 then
        set thePerson to item 1 of matchingPeople

        -- Try to get phone number first
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

if [ -n "$CONTACT_INFO" ]; then
    echo "$CONTACT_INFO"
    exit 0
else
    exit 1
fi
