#!/bin/bash
set -euo pipefail

APP_DIR="/Applications/SpoofTrap"
SUPPORT_DIR="$HOME/Library/Application Support/SpoofTrap"

printf 'Remove %s and %s? [y/N]: ' "$APP_DIR" "$SUPPORT_DIR"
read -r answer

case "$answer" in
    y|Y|yes|YES)
        rm -rf "$APP_DIR"
        rm -rf "$SUPPORT_DIR"
        printf 'SpoofTrap removed.\n'
        ;;
    *)
        printf 'Cancelled.\n'
        ;;
esac
