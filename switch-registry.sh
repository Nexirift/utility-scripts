#!/bin/bash

NEXIRIFT_URL="https://code.nexirift.com/dev/~npm/"
LOCALHOST_URL="http://localhost:4873"

# Update .npmrc
NPM_RC_PATH=".npmrc"
if [ -f "$NPM_RC_PATH" ]; then
  if grep -q "code.nexirift.com" "$NPM_RC_PATH"; then
    sed -i "s|^@nexirift:registry = \"$NEXIRIFT_URL\"|@nexirift:registry = \"$LOCALHOST_URL\"|" "$NPM_RC_PATH"
    echo ".npmrc updated to localhost."
  else
    sed -i "s|^@nexirift:registry = \"$LOCALHOST_URL\"|@nexirift:registry = \"$NEXIRIFT_URL\"|" "$NPM_RC_PATH"
    echo ".npmrc updated to nexirift.com."
  fi
else
  echo ".npmrc not found."
fi

# Update bunfig.toml
BUNFIG_TOML_PATH="bunfig.toml"
if [ -f "$BUNFIG_TOML_PATH" ]; then
  if grep -q "code.nexirift.com" "$BUNFIG_TOML_PATH"; then
    sed -i "s|^\"@nexirift\" = { url = \"$NEXIRIFT_URL\" }|\"@nexirift\" = { url = \"$LOCALHOST_URL/\" }|" "$BUNFIG_TOML_PATH"
    echo "bunfig.toml updated to localhost."
  else
    sed -i "s|^\"@nexirift\" = { url = \"$LOCALHOST_URL\/\" }|\"@nexirift\" = { url = \"$NEXIRIFT_URL\" }|" "$BUNFIG_TOML_PATH"
    echo "bunfig.toml updated to nexirift.com."
  fi
else
  echo "bunfig.toml not found."
fi
