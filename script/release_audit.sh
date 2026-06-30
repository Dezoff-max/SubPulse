#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="SubPulse"
APP_PATH="$ROOT_DIR/dist/$APP_NAME.app"
DMG_PATH="$ROOT_DIR/dist/$APP_NAME.dmg"

cd "$ROOT_DIR"

echo "== Tests =="
swift test

echo
echo "== Release build =="
swift build -c release

echo
echo "== App bundle verification =="
BUILD_CONFIGURATION=release "$ROOT_DIR/script/build_and_run.sh" --build
VERIFY_DIR="$(mktemp -d /tmp/subpulse-release-verify.XXXXXX)"
VERIFY_APP="$VERIFY_DIR/$APP_NAME.app"
ditto --norsrc --noextattr --noacl "$APP_PATH" "$VERIFY_APP"
xattr -cr "$VERIFY_APP" >/dev/null 2>&1 || true
codesign --verify --deep --strict --verbose=2 "$VERIFY_APP"
rm -rf "$VERIFY_DIR"

echo
echo "== DMG build and verification =="
"$ROOT_DIR/build_dmg.sh"
hdiutil verify "$DMG_PATH"

echo
echo "== DMG contents =="
MOUNT_DIR="$(mktemp -d /tmp/subpulse-release-audit.XXXXXX)"
cleanup_mount() {
  hdiutil detach "$MOUNT_DIR" >/dev/null 2>&1 || true
  rmdir "$MOUNT_DIR" >/dev/null 2>&1 || true
}
trap cleanup_mount EXIT
hdiutil attach -nobrowse -readonly -mountpoint "$MOUNT_DIR" "$DMG_PATH" >/dev/null
find "$MOUNT_DIR" -maxdepth 1 -mindepth 1 -exec basename {} \; | sort
test -d "$MOUNT_DIR/$APP_NAME.app"
test -e "$MOUNT_DIR/Applications"
test -f "$MOUNT_DIR/Инструкция по установке.txt"
cleanup_mount
trap - EXIT

echo
echo "== Developer ID identity =="
if security find-identity -p codesigning -v | grep -q "Developer ID Application"; then
  security find-identity -p codesigning -v | grep "Developer ID Application"
  echo "Developer ID identity found."
else
  echo "Developer ID identity not found."
  echo "Install an Apple Developer ID Application certificate before notarization."
fi

echo
echo "Release audit finished."
