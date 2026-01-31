#!/bin/bash

# List named group chats
# Usage: ./list_chats.sh [query] [--limit N]

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
            QUERY="$1"
            shift
            ;;
    esac
done

osascript <<EOF | if [ -n "$LIMIT" ]; then head -n "$LIMIT"; else cat; fi
tell application "Messages"
    set namedChats to {}
    set allChats to every chat
    repeat with aChat in allChats
        set chatName to name of aChat
        if chatName is not missing value then
            if "$QUERY" is "" or chatName contains "$QUERY" then
                set end of namedChats to chatName
            end if
        end if
    end repeat
    if (count of namedChats) is 0 then
        return "No named group chats found"
    end if
    set AppleScript's text item delimiters to "
"
    return namedChats as text
end tell
EOF
