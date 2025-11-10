#!/bin/sh

set -e

SCRIPTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$HOME/dotfiles"

# ~/.inputrc
INPUTRC="$HOME/.inputrc"
INPUTRC_INCLUDE="\$include $DOTFILES/.inputrc"

if [ ! -f "$INPUTRC" ]; then
  echo ".inputrc not found at $INPUTRC"
  exit 1
fi

if grep -Fxq "$INPUTRC_INCLUDE" "$INPUTRC"; then
  echo "Reference to custom .inputrc already exists."
else
  echo "" >> "$INPUTRC"
  echo "$INPUTRC_INCLUDE" >> "$INPUTRC"
fi

# ~/.config/hypr/autostart.conf
AUTOSTART="$HOME/.config/hypr/autostart.conf"
AUTOSTART_SOURCE="source = $DOTFILES/.config/hypr/autostart.conf"

if [ ! -f "$AUTOSTART" ]; then
  echo "autostart.conf not found at $AUTOSTART"
  exit 1
fi

if grep -Fxq "$AUTOSTART_SOURCE" "$AUTOSTART"; then
  echo "Reference to custom autostart.conf already exists."
else
  echo "" >> "$AUTOSTART"
  echo "$AUTOSTART_SOURCE" >> "$AUTOSTART"
fi

# ~/.config/hypr/input.conf
INPUT="$HOME/.config/hypr/input.conf"
INPUT_SOURCE="source = $DOTFILES/.config/hypr/input.conf"

if [ ! -f "$INPUT" ]; then
  echo "input.conf not found at $INPUT"
  exit 1
fi

if grep -Fxq "$INPUT_SOURCE" "$INPUT"; then
  echo "Reference to custom input.conf already exists."
else
  echo "" >> "$INPUT"
  echo "$INPUT_SOURCE" >> "$INPUT"
fi

# ~/.config/hypr/bindings.conf
BINDINGS="$HOME/.config/hypr/bindings.conf"
BINDINGS_SOURCE="source = $DOTFILES/.config/hypr/bindings.conf"

if [ ! -f "$BINDINGS" ]; then
  echo "bindings.conf not found at $BINDINGS"
  exit 1
fi

if grep -Fxq "$BINDINGS_SOURCE" "$BINDINGS"; then
  echo "Reference to custom bindings.conf already exists."
else
  echo "" >> "$BINDINGS"
  echo "$BINDINGS_SOURCE" >> "$BINDINGS"
fi

# ~/.config/hypr/hyprsunset.conf
SUNSET="$HOME/.config/hypr/hyprsunset.conf"
SUNSET_SOURCE="source = $DOTFILES/.config/hypr/hyprsunset.conf"

if [ ! -f "$SUNSET" ]; then
  echo "hyprsunset.conf not found at $SUNSET"
  exit 1
fi

if grep -Fxq "$SUNSET_SOURCE" "$SUNSET"; then
  echo "Reference to custom hyprsunset.conf already exists."
else
  echo "" >> "$SUNSET"
  echo "$SUNSET_SOURCE" >> "$SUNSET"
fi

echo "Finished!"

