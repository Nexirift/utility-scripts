#!/bin/bash
#
# Switch between registry configurations (local vs remote)

# Exit on command errors and unset variables
set -o errexit
set -o nounset

NEXIRIFT_URL="https://code.nexirift.com/dev/~npm/"
LOCALHOST_URL="http://localhost:4873"

# Function to update config files
update_registry() {
  local current_registry="$1"
  local target_registry="$2"
  local display_name="$3"
  local current_url="$4"
  local target_url="$5"

  echo -e "${BLUE}Switching to ${display_name} registry${RESET}"

  # Update .npmrc
  NPM_RC_PATH=".npmrc"
  if [ -f "$NPM_RC_PATH" ]; then
    if grep -q "$current_registry" "$NPM_RC_PATH"; then
      sed -i "s|^@nexirift:registry = \"$current_url\"|@nexirift:registry = \"$target_url\"|" "$NPM_RC_PATH" && \
      echo -e "${GREEN}✓ .npmrc updated to ${display_name}.${RESET}"
    else
      echo -e "${YELLOW}! .npmrc does not contain the expected registry URL.${RESET}"
      echo -e "${YELLOW}! Creating backup at .npmrc.bak before modifying${RESET}"
      cp "$NPM_RC_PATH" "${NPM_RC_PATH}.bak"
      echo "@nexirift:registry = \"$target_url\"" > "$NPM_RC_PATH"
      echo -e "${GREEN}✓ .npmrc updated to ${display_name}.${RESET}"
    fi
  else
    echo -e "${YELLOW}! .npmrc not found.${RESET}"
    echo "@nexirift:registry = \"$target_url\"" > "$NPM_RC_PATH"
    echo -e "${GREEN}✓ .npmrc created with ${display_name} registry.${RESET}"
  fi

  # Update bunfig.toml
  BUNFIG_TOML_PATH="bunfig.toml"
  if [ -f "$BUNFIG_TOML_PATH" ]; then
    # Ensure trailing slash for localhost URL in bunfig.toml
    local target_bun_url="$target_url"
    if [ "$target_url" = "$LOCALHOST_URL" ]; then
      target_bun_url="${target_url}/"
    fi

    if grep -q "$current_registry" "$BUNFIG_TOML_PATH"; then
      local current_bun_url="$current_url"
      if [ "$current_url" = "$LOCALHOST_URL" ]; then
        current_bun_url="${current_url}/"
      fi

      sed -i "s|^\"@nexirift\" = { url = \"$current_bun_url\" }|\"@nexirift\" = { url = \"$target_bun_url\" }|" "$BUNFIG_TOML_PATH" && \
      echo -e "${GREEN}✓ bunfig.toml updated to ${display_name}.${RESET}"
    else
      echo -e "${YELLOW}! bunfig.toml does not contain the expected registry URL.${RESET}"
      echo -e "${YELLOW}! Creating backup at bunfig.toml.bak before modifying${RESET}"
      cp "$BUNFIG_TOML_PATH" "${BUNFIG_TOML_PATH}.bak"
      echo "[install.scopes]" > "$BUNFIG_TOML_PATH"
      echo "\"@nexirift\" = { url = \"$target_bun_url\" }" >> "$BUNFIG_TOML_PATH"
      echo -e "${GREEN}✓ bunfig.toml updated to ${display_name}.${RESET}"
    fi
  else
    echo -e "${YELLOW}! bunfig.toml not found.${RESET}"
    echo "[install.scopes]" > "$BUNFIG_TOML_PATH"
    local target_bun_url="$target_url"
    if [ "$target_url" = "$LOCALHOST_URL" ]; then
      target_bun_url="${target_url}/"
    fi
    echo "\"@nexirift\" = { url = \"$target_bun_url\" }" >> "$BUNFIG_TOML_PATH"
    echo -e "${GREEN}✓ bunfig.toml created with ${display_name} registry.${RESET}"
  fi
}

# Determine current registry and switch
if [ -f ".npmrc" ] && grep -q "code.nexirift.com" ".npmrc"; then
  update_registry "code.nexirift.com" "localhost" "localhost" "$NEXIRIFT_URL" "$LOCALHOST_URL"
else
  update_registry "localhost" "code.nexirift.com" "nexirift.com" "$LOCALHOST_URL" "$NEXIRIFT_URL"
fi

echo -e "${GREEN}Registry switch completed.${RESET}"
