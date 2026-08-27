#!/usr/bin/env bash

set -euo pipefail

repo_root=${HOME:?HOME is not set}/dotfiles
script_directory=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

if [[ ! -d $repo_root ]]; then
  printf 'Expected the dotfiles repository at: %s\n' "$repo_root" >&2
  exit 1
fi

"$repo_root/scripts/home-manager-switch"
"$script_directory/install-via-omarchy.sh"

cat <<EOF

User-level setup is complete.

Root-owned system configuration is intentionally separate. Review and apply it with:

  sudo install -D -m 0644 \
    "$repo_root/etc/systemd/system/systemd-poweroff.service.d/override.conf" \
    /etc/systemd/system/systemd-poweroff.service.d/override.conf
  sudo systemctl daemon-reload
EOF
