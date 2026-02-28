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

# ~/.config/hypr/*.conf
for hypr_config in autostart input bindings looknfeel hyprsunset; do
  target_file="$HOME/.config/hypr/${hypr_config}.conf"
  source_line="source = $DOTFILES/.config/hypr/${hypr_config}.conf"

  ensure_reference \
    "$target_file" \
    "$source_line" \
    "${hypr_config}.conf not found at $target_file" \
    "Reference to custom ${hypr_config}.conf already exists."
done

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

