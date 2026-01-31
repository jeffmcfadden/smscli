#!/bin/bash

# Search contacts by name
# Usage: ./search_contacts.sh <query> [--limit N]
# Returns matching contacts with their phone numbers and emails

QUERY=""
LIMIT=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --limit|-n)
            LIMIT="$2"
            shift 2
            ;;
        *)
            if [ -z "$QUERY" ]; then
                QUERY="$1"
            fi
            shift
            ;;
    esac
done

if [ -z "$QUERY" ]; then
    echo "Usage: $0 <query> [--limit N]" >&2
    exit 1
fi

# Default limit to large number if not specified
LIMIT="${LIMIT:-9999}"

osascript <<EOF
tell application "Contacts" to launch
delay 0.5

-- Helper to clean up label names
on cleanLabel(rawLabel)
    set cleanedLabel to rawLabel
    -- Remove Apple's internal label format markers
    if rawLabel contains "_\$!<" then
        set cleanedLabel to text 5 thru -5 of rawLabel
    end if
    return cleanedLabel
end cleanLabel

tell application "Contacts"
    set matchingPeople to (every person whose name contains "$QUERY")
    set output to ""
    set contactCount to 0
    set maxContacts to $LIMIT

    repeat with thePerson in matchingPeople
        if contactCount ≥ maxContacts then exit repeat
        set contactCount to contactCount + 1

        set personName to name of thePerson
        set personInfo to personName

        -- Get phone numbers
        set thePhones to phones of thePerson
        repeat with thePhone in thePhones
            set phoneLabel to my cleanLabel(label of thePhone)
            set phoneValue to value of thePhone
            set personInfo to personInfo & "
    " & phoneLabel & ": " & phoneValue
        end repeat

        -- Get emails
        set theEmails to emails of thePerson
        repeat with theEmail in theEmails
            set emailLabel to my cleanLabel(label of theEmail)
            set emailValue to value of theEmail
            set personInfo to personInfo & "
    " & emailLabel & ": " & emailValue
        end repeat

        set output to output & personInfo & "
"
    end repeat
    if output is "" then
        return "No contacts found matching \"$QUERY\""
    end if
    return output
end tell
EOF
