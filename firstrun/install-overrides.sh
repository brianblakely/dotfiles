#!/bin/sh

set -e

DOTFILES="$HOME/dotfiles"

ensure_reference() {
  target_file="$1"
  source_line="$2"
  missing_message="$3"
  existing_message="$4"

  if [ ! -f "$target_file" ]; then
    echo "$missing_message"
    exit 1
  fi

  if grep -Fxq "$source_line" "$target_file"; then
    echo "$existing_message"
  else
    printf "\n%s\n" "$source_line" >> "$target_file"
  fi
}

# ~/.inputrc
INPUTRC="$HOME/.inputrc"
INPUTRC_INCLUDE="\$include $DOTFILES/.inputrc"
ensure_reference \
  "$INPUTRC" \
  "$INPUTRC_INCLUDE" \
  ".inputrc not found at $INPUTRC" \
  "Reference to custom .inputrc already exists."

# ~/.config/hypr/hyprland.lua
HYPRLAND_MAIN="$HOME/.config/hypr/hyprland.lua"
HYPRLAND_OVERRIDE='dofile((os.getenv("HOME") or "") .. "/dotfiles/.config/hypr/hyprland.lua")'
ensure_reference \
  "$HYPRLAND_MAIN" \
  "$HYPRLAND_OVERRIDE" \
  "hyprland.lua not found at $HYPRLAND_MAIN" \
  "Reference to custom hyprland.lua already exists."

# ~/.config/hypr/hyprsunset.conf (hyprsunset uses Hyprlang, not Lua)
HYPRSUNSET="$HOME/.config/hypr/hyprsunset.conf"
HYPRSUNSET_SOURCE="source = $DOTFILES/.config/hypr/hyprsunset.conf"
ensure_reference \
  "$HYPRSUNSET" \
  "$HYPRSUNSET_SOURCE" \
  "hyprsunset.conf not found at $HYPRSUNSET" \
  "Reference to custom hyprsunset.conf already exists."

echo "Finished!"
