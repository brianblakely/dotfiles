#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WAYBAR_PEEK_SCRIPT="$SCRIPT_DIR/waybar-peek.sh"

socket="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

if [[ ! -S "$socket" ]]; then
  echo "Socket not found: $socket" >> /tmp/waybar-workspace-listener.log
  exit 1
fi

socat -U - "UNIX-CONNECT:$socket" | while IFS= read -r line; do
  case "$line" in
    workspace'>>'*|workspacev2'>>'*)
      "$WAYBAR_PEEK_SCRIPT" &
      ;;
  esac
done