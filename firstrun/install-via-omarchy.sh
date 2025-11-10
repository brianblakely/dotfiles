#!/bin/sh

omarchy-install-chromium-google-account

if ! pacman -Q visual-studio-code-bin > /dev/null 2>&1; then
	omarchy-install-vscode
else
	echo "visual-studio-code-bin is already installed, skipping..."
fi
