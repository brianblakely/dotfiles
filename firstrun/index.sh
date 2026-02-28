#!/bin/sh

set -e

# Install other packages
. ./install-brave.sh

# Installs that have Omarchy installer
. ./install-via-omarchy.sh

# Configuration overrides
. ./install-overrides.sh
