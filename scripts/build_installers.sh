#!/usr/bin/env bash
# From dist/SpoofTrap.app (after package_macos_app.sh): ZIP, DMG, PKG, then copy into docs/dist/ for the website.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/dist/SpoofTrap.app"
cd "$ROOT/dist"

if [[ ! -d "$APP" ]]; then
  echo "error: missing $APP — run scripts/package_macos_app.sh first" >&2
  exit 1
fi

VER="$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$APP/Contents/Info.plist")"
echo "==> Building installers for version $VER"

rm -f SpoofTrap.zip SpoofTrap.dmg SpoofTrap.pkg
ditto -c -k --keepParent SpoofTrap.app SpoofTrap.zip
hdiutil create -volname "SpoofTrap" -srcfolder SpoofTrap.app -ov -format UDZO SpoofTrap.dmg -quiet
pkgbuild --root SpoofTrap.app --identifier com.spooftrap.app --version "$VER" --install-location /Applications/SpoofTrap.app SpoofTrap.pkg

mkdir -p "$ROOT/docs/dist"
cp -f SpoofTrap.zip SpoofTrap.dmg SpoofTrap.pkg "$ROOT/docs/dist/"

echo "==> SHA-256 (paste into docs/dist/latest.json)"
shasum -a 256 SpoofTrap.pkg SpoofTrap.zip SpoofTrap.dmg

echo "OK: dist/ and docs/dist/ updated. Bump latest.json version/changelog, then commit both repos."
