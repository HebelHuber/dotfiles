#!/bin/bash

# Hardcoded GitHub username
GITHUB_USER="HebelHuber"

# Path to authorized_keys file
AUTH_KEYS_FILE="/root/.ssh/authorized_keys"

# Temporary file for downloaded keys
TEMP_KEYS_FILE=$(mktemp)

# Check if we received a username argument (SSH passes the username as the first argument)
if [ $# -ge 1 ]; then
    SSH_USER="$1"
else
    echo "No username provided" >&2
    exit 1
fi

# Function to check if key exists in authorized_keys
key_exists() {
    grep -qF "$1" "$AUTH_KEYS_FILE"
}

# Function to fetch keys from GitHub
fetch_github_keys() {
    # Fetch keys from GitHub
    if ! curl -sf "https://github.com/${GITHUB_USER}.keys" > "$TEMP_KEYS_FILE"; then
        echo "Failed to fetch keys from GitHub" >&2
        rm -f "$TEMP_KEYS_FILE"
        exit 1
    fi

    # Process each key
    while read -r key; do
        # Skip empty lines
        [ -z "$key" ] && continue
        
        # Check if key already exists
        if ! key_exists "$key"; then
            # Append to authorized_keys
            echo "$key" >> "$AUTH_KEYS_FILE"
        fi
    done < "$TEMP_KEYS_FILE"

    # Clean up
    rm -f "$TEMP_KEYS_FILE"
}

# First check - look for existing keys
if [ -f "$AUTH_KEYS_FILE" ]; then
    # SSH expects the keys to be printed to stdout if found
    grep "$SSH_USER" "$AUTH_KEYS_FILE" && exit 0
fi

# If no match found, fetch from GitHub
fetch_github_keys

# Second check - look again after updating
if [ -f "$AUTH_KEYS_FILE" ]; then
    grep "$SSH_USER" "$AUTH_KEYS_FILE" && exit 0
fi

# If still no match
exit 1