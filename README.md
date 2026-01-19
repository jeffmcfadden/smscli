# smscli

Send iMessages from the command line on macOS via AppleScript.

## Installation

**Quick install:**
```bash
curl -fsSL https://raw.githubusercontent.com/jeffmcfadden/smscli/main/sms | sudo tee /usr/local/bin/sms > /dev/null && sudo chmod +x /usr/local/bin/sms
```

**Manual install:**
```bash
sudo cp sms /usr/local/bin/sms
sudo chmod +x /usr/local/bin/sms
```

## Usage

```bash
# Send to phone number
sms "+15551234567" "Hello!"

# Send to email
sms "user@example.com" "Hello!"

# Send to contact by name (looks up in Contacts.app)
sms "John Smith" "Hello!"

# Send to group chat by name
sms "Family" "Hello everyone!"

# Search contacts
sms --search "John"
sms -s "Smith"

# List named group chats
sms --chats
sms -c "Family"    # filter by name

# List recent messages from a conversation (experimental)
sms --list "Family"          # last 5 messages
sms --list "John Smith" 10   # last 10 messages
sms -l "+15551234567" 3      # last 3 messages
```

**Note:** `--list` is experimental and may have formatting issues with some messages (e.g., emoji, reactions).

## Audit Log

All sends are logged to the macOS system log. Query with:

```bash
log show --predicate 'process == "logger"' --last 1h
```

## Requirements

- macOS with Messages.app configured
- Contacts.app for name lookups
- Full Disk Access for Terminal (only needed for `--list` to read message history)
  - Grant in: System Settings > Privacy & Security > Full Disk Access
