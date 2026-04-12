#!/usr/bin/env bash
# Assemble dist/SpoofTrap.app with the release binary AND bundled spoofdpi.
# spoofdpi source of truth: Sources/Resources/bin/spoofdpi (drop a new binary there if you update it).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "==> swift build -c release"
swift build -c release

APP="$ROOT/dist/SpoofTrap.app"
EXEC_DST="$APP/Contents/MacOS/SpoofTrap"
RES_BIN="$APP/Contents/Resources/bin"
SRC_SPOOFDPI="$ROOT/Sources/Resources/bin/spoofdpi"
BUNDLE_SRC="$ROOT/.build/release/SpoofTrap_SpoofTrap.bundle"

if [[ ! -f "$ROOT/.build/release/SpoofTrap" ]]; then
  echo "error: .build/release/SpoofTrap not found after build" >&2
  exit 1
fi
if [[ ! -f "$SRC_SPOOFDPI" ]]; then
  echo "error: missing $SRC_SPOOFDPI — add the macOS spoofdpi binary there, then re-run." >&2
  exit 1
fi

mkdir -p "$APP/Contents/MacOS"
cp -f "$ROOT/.build/release/SpoofTrap" "$EXEC_DST"
chmod +x "$EXEC_DST"

mkdir -p "$RES_BIN"
cp -f "$SRC_SPOOFDPI" "$RES_BIN/spoofdpi"
chmod +x "$RES_BIN/spoofdpi"

# Same layout as SwiftPM so locateResourceBundle() finds bin/spoofdpi if needed
if [[ -d "$BUNDLE_SRC" ]]; then
  rm -rf "$APP/Contents/Resources/SpoofTrap_SpoofTrap.bundle"
  cp -R "$BUNDLE_SRC" "$APP/Contents/Resources/"
fi

echo "==> codesign (ad-hoc, deep)"
codesign --force --deep --sign - "$APP"
xattr -cr "$APP"
codesign -vvv "$APP"

echo "OK: $APP"
echo "    bundled: $RES_BIN/spoofdpi ($(wc -c < "$RES_BIN/spoofdpi" | tr -d ' ') bytes)"
echo "Next: bump Info.plist version if needed, then ditto/hdiutil/pkgbuild for ZIP/DMG/PKG (see README)."
