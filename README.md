# smscli

Send iMessages from the command line on macOS via AppleScript.

## Installation

**Quick install:**
```bash
git clone https://github.com/jeffmcfadden/smscli.git ~/.smscli
echo 'export PATH="$HOME/.smscli:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

**Manual install:**
```bash
git clone https://github.com/jeffmcfadden/smscli.git
cd smscli
sudo cp sms contact_lookup.sh list_chats.sh list_messages.sh search_contacts.sh send_message.sh /usr/local/bin/
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

# List recent messages from a conversation
sms --list "Family"          # last 10 messages
sms --list "John Smith" 20   # last 20 messages
sms -l "+15551234567" 5      # last 5 messages
```

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
