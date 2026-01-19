#!/bin/bash

# List recent messages from a chat
# Usage: ./list_messages.sh <chat_name_or_contact> [count]
# Supports: group chat names, phone numbers, emails, or contact names

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CHAT_NAME="$1"
COUNT="${2:-10}"

if [ -z "$CHAT_NAME" ]; then
    echo "Usage: $0 <chat_name_or_contact> [count]" >&2
    exit 1
fi

# Try to resolve contact name to phone/email if needed
if [[ "$CHAT_NAME" != *"@"* ]] && [[ "$CHAT_NAME" != "+"* ]]; then
    digits_only=$(echo "$CHAT_NAME" | tr -cd '0-9')
    if [[ ${#digits_only} -lt 7 ]]; then
        # Might be a contact name - try to resolve it
        if [ -x "$SCRIPT_DIR/contact_lookup.sh" ]; then
            RESOLVED=$("$SCRIPT_DIR/contact_lookup.sh" "$CHAT_NAME" 2>/dev/null)
            if [ -n "$RESOLVED" ]; then
                CHAT_NAME="$RESOLVED"
            fi
            # If not resolved, continue with original name (might be a group chat)
        fi
    fi
fi

python3 << EOF
import sqlite3
import os
from datetime import datetime

def extract_text_from_attributed_body(data):
    """Extract plain text from NSAttributedString blob."""
    if not data:
        return None

    # Find NSString marker
    marker = b'NSString'
    idx = data.find(marker)
    if idx == -1:
        return None

    remaining = data[idx + len(marker):]

    # Find + marker
    plus_idx = remaining.find(b'+')
    if plus_idx == -1:
        return None

    after_plus = remaining[plus_idx + 1:]

    # Handle variable length encoding
    first_byte = after_plus[0]

    if first_byte < 0x80:
        # Simple length encoding
        length = first_byte
        text_start = 1
    else:
        # Extended encoding - skip header bytes until we find text
        text_start = 1
        while text_start < min(10, len(after_plus)):
            b = after_plus[text_start]
            # Stop at printable ASCII or UTF-8 lead byte
            if (0x20 <= b <= 0x7E) or (b >= 0xC0):
                break
            text_start += 1
        length = 2000  # Read plenty, trim at end marker

    text_bytes = after_plus[text_start:text_start + length]

    # Find end marker (0x86 followed by 0x84 is common terminator)
    text_end = len(text_bytes)
    for i in range(len(text_bytes) - 1):
        if text_bytes[i] == 0x86 and (i + 1 >= len(text_bytes) or text_bytes[i + 1] == 0x84):
            text_end = i
            break

    text_bytes = text_bytes[:text_end]

    try:
        text = text_bytes.decode('utf-8')
    except:
        text = text_bytes.decode('utf-8', errors='replace')

    # Clean up: remove object replacement characters and other junk
    # \ufffc = object replacement, \ufffd = replacement char, \ufeff = BOM
    text = text.lstrip('\ufffc\ufffd\ufeff\x00\x01\x02\x03\x04\x05 ')
    text = text.replace('\ufffc', '').replace('\ufffd', '').strip()

    return text if text else None

db_path = os.path.expanduser("~/Library/Messages/chat.db")

if not os.access(db_path, os.R_OK):
    print("Error: Cannot read Messages database.")
    print("Grant Full Disk Access to Terminal in System Settings > Privacy & Security.")
    exit(1)

conn = sqlite3.connect(db_path)
cursor = conn.cursor()

chat_name = """$CHAT_NAME"""
count = $COUNT

# Find chat ID - exact match first
cursor.execute("SELECT ROWID FROM chat WHERE display_name = ? LIMIT 1", (chat_name,))
row = cursor.fetchone()
chat_id = row[0] if row else None

# Try partial match if no exact match
if not chat_id:
    cursor.execute("""
        SELECT ROWID FROM chat
        WHERE display_name LIKE ? OR chat_identifier LIKE ?
        LIMIT 1
    """, (f"%{chat_name}%", f"%{chat_name}%"))
    row = cursor.fetchone()
    chat_id = row[0] if row else None

if not chat_id:
    print(f"No chat found matching '{chat_name}'")
    exit(1)

# Get messages
cursor.execute("""
    SELECT
        m.ROWID,
        m.date,
        m.is_from_me,
        COALESCE(h.id, '') as handle,
        m.text,
        m.attributedBody,
        m.associated_message_type
    FROM message m
    LEFT JOIN handle h ON m.handle_id = h.ROWID
    JOIN chat_message_join cmj ON m.ROWID = cmj.message_id
    WHERE cmj.chat_id = ?
    ORDER BY m.date DESC
    LIMIT ?
""", (chat_id, count))

messages = []
for row in cursor.fetchall():
    rowid, date_val, is_from_me, handle, text, attr_body, assoc_type = row

    # Convert Apple's timestamp to datetime
    if date_val:
        # Apple uses nanoseconds since 2001-01-01
        timestamp = date_val / 1000000000 + 978307200
        date_str = datetime.fromtimestamp(timestamp).strftime('%Y-%m-%d %H:%M:%S')
    else:
        date_str = "Unknown"

    # Determine sender
    sender = "Me" if is_from_me else (handle or "Unknown")

    # Get text content
    if text:
        content = text
    elif attr_body:
        content = extract_text_from_attributed_body(attr_body)
    else:
        content = None

    # Skip reaction/tapback messages (associated_message_type 2000-3999)
    if assoc_type and 2000 <= assoc_type < 4000:
        continue

    if content:
        messages.append((date_str, sender, content))

conn.close()

# Print in chronological order (oldest first)
for date_str, sender, content in reversed(messages):
    print(f"[{date_str}] {sender}: {content}")
EOF
