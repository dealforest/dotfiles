#!/bin/bash
# Sync plugins from settings.json enabledPlugins
# This script is called on SessionStart to ensure all enabled plugins are installed

SETTINGS_FILE="$HOME/.claude/settings.json"

if [[ ! -f "$SETTINGS_FILE" ]]; then
  exit 0
fi

# Extract plugin names from enabledPlugins (supports both jq and grep fallback)
if command -v jq &>/dev/null; then
  plugins=$(jq -r '.enabledPlugins // {} | keys[]' "$SETTINGS_FILE" 2>/dev/null)
else
  # Fallback: grep-based extraction
  plugins=$(grep -oE '"[^"]+@[^"]+":\s*true' "$SETTINGS_FILE" | sed 's/"//g; s/:.*//; s/@.*//')
fi

for plugin in $plugins; do
  # Extract plugin name without marketplace suffix
  plugin_name="${plugin%%@*}"

  # Check if already installed (suppress output)
  if ! claude plugins list 2>/dev/null | grep -q "$plugin_name"; then
    claude plugins install "$plugin_name" 2>/dev/null || true
  fi
done
