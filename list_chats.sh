#!/bin/bash

# List named group chats
# Usage: ./list_chats.sh [query]
# If query is provided, filters chats by name

QUERY="$1"

osascript <<EOF
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
