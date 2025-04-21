#!/bin/bash

NEXIRIFT_URL="https://code.nexirift.com/dev/~npm/"
LOCALHOST_URL="http://localhost:4873"

# Parse arguments
TEST_PRELOAD_FILES=""
for arg in "$@"; do
  if [[ "$arg" == "--test-preload="* ]]; then
    TEST_PRELOAD_FILES="${arg#*=}"
  fi
done

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
  echo "Creating .npmrc file..."
  echo "@nexirift:registry = \"$NEXIRIFT_URL\"" > "$NPM_RC_PATH"
  echo ".npmrc created with nexirift.com registry."
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
  echo "Creating bunfig.toml file..."
  echo "[install.scopes]" > "$BUNFIG_TOML_PATH"
  echo "\"@nexirift\" = { url = \"$NEXIRIFT_URL\" }" >> "$BUNFIG_TOML_PATH"
  echo "bunfig.toml created with nexirift.com registry."
fi

# Add test preload configuration if specified in arguments
if [ -n "$TEST_PRELOAD_FILES" ]; then
  if [ -f "$BUNFIG_TOML_PATH" ]; then
    # Check if test section already exists
    if ! grep -q "\[test\]" "$BUNFIG_TOML_PATH"; then
      echo "" >> "$BUNFIG_TOML_PATH"
      echo "[test]" >> "$BUNFIG_TOML_PATH"
      echo "preload = $TEST_PRELOAD_FILES" >> "$BUNFIG_TOML_PATH"
      echo "Added test preload configuration to bunfig.toml."
    else
      # Update existing test section with new preload arguments
      # Escape the TEST_PRELOAD_FILES variable to avoid sed issues
      ESCAPED_PRELOAD=$(printf '%s\n' "$TEST_PRELOAD_FILES" | sed 's/[\/&]/\\&/g')
      sed -i "/\\[test\\]/,/^$/s/preload = .*/preload = $ESCAPED_PRELOAD/" "$BUNFIG_TOML_PATH"
      echo "Updated existing test preload configuration in bunfig.toml."
    fi
  fi
fi
