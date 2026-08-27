#!/usr/bin/env bash

set -euo pipefail

# Compatibility entry point. Home Manager activation and the Omarchy
# post-update hook both call the same implementation directly.
exec "${HOME:?HOME is not set}/dotfiles/scripts/reconcile-config-imports" "$@"
