#!/bin/bash
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
exec bash "$DIR/SpoofTrap.app/Contents/Resources/spooftrap.sh"
