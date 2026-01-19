# smscli

Send iMessages from the command line on macOS via AppleScript.

## Installation

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
```

## Audit Log

All sends are logged to the macOS system log. Query with:

```bash
log show --predicate 'process == "logger"' --last 1h
```

## Requirements

- macOS with Messages.app configured
- Contacts.app for name lookups
