#!/usr/bin/env bash

set -euo pipefail

# This Omarchy helper is internally idempotent: it only adds missing flags.
omarchy install chromium google account

if flatpak info --user com.nvidia.geforcenow >/dev/null 2>&1 ||
  flatpak info --system com.nvidia.geforcenow >/dev/null 2>&1; then
  echo 'GeForce NOW is already installed, skipping...'
else
  omarchy install gaming geforce-now
fi

if pacman -Q brave-bin >/dev/null 2>&1; then
  echo 'brave-bin is already installed, skipping...'
else
  omarchy install browser brave
fi

if pacman -Q visual-studio-code-bin >/dev/null 2>&1; then
  echo 'visual-studio-code-bin is already installed, skipping...'
else
  omarchy install editor vscode
fi
