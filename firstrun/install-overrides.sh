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

# ~/.config/hypr/looknfeel.conf
LOOKNFEEL="$HOME/.config/hypr/looknfeel.conf"
LOOKNFEEL_SOURCE="source = $DOTFILES/.config/hypr/looknfeel.conf"

if [ ! -f "$LOOKNFEEL" ]; then
  echo "looknfeel.conf not found at $LOOKNFEEL"
  exit 1
fi

if grep -Fxq "$LOOKNFEEL_SOURCE" "$LOOKNFEEL"; then
  echo "Reference to custom looknfeel.conf already exists."
else
  echo "" >> "$LOOKNFEEL"
  echo "$LOOKNFEEL_SOURCE" >> "$LOOKNFEEL"
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

# ~/.config/waybar/config.jsonc
WAYBAR="$HOME/.config/waybar/config.jsonc"
WAYBAR_INCLUDE="$DOTFILES/.config/waybar/config.jsonc"

if [ ! -f "$WAYBAR" ]; then
  echo "waybar config not found at $WAYBAR"
  exit 1
fi

if [ ! -f "$WAYBAR_INCLUDE" ]; then
  echo "custom waybar config not found at $WAYBAR_INCLUDE"
  exit 1
fi

if grep -Fq "\"$WAYBAR_INCLUDE\"" "$WAYBAR"; then
  echo "Reference to custom waybar config already exists."
elif grep -Eq '"include"[[:space:]]*:[[:space:]]*\[' "$WAYBAR"; then
  TMPFILE="$(mktemp)"

  awk -v inc_path="$WAYBAR_INCLUDE" '
    BEGIN { inserted = 0 }
    {
      if (!inserted && $0 ~ /"include"[[:space:]]*:[[:space:]]*\[/) {
        print $0
        if (getline nextline) {
          if (nextline ~ /^[[:space:]]*\]/) {
            print "    \"" inc_path "\""
            print nextline
          } else {
            print "    \"" inc_path "\"," 
            print nextline
          }
        }
        inserted = 1
        next
      }
      print $0
    }
  ' "$WAYBAR" > "$TMPFILE"

  mv "$TMPFILE" "$WAYBAR"
  echo "Added reference to custom waybar config."
else
  TMPFILE="$(mktemp)"

  awk -v inc_path="$WAYBAR_INCLUDE" '
    BEGIN { inserted = 0 }
    {
      print $0
      if (!inserted && $0 ~ /\{/) {
        print "  \"include\": [\"" inc_path "\"],"
        inserted = 1
      }
    }
  ' "$WAYBAR" > "$TMPFILE"

  mv "$TMPFILE" "$WAYBAR"
  echo "Added reference to custom waybar config."
fi

echo "Finished!"

