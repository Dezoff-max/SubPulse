#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="SubPulse"
APP_PATH="$ROOT_DIR/dist/$APP_NAME.app"
DMG_PATH="$ROOT_DIR/dist/$APP_NAME.dmg"
APP_ICON="$ROOT_DIR/Resources/AppIcon.icns"
STAGE_DIR="$(mktemp -d /tmp/subpulse-dmg.XXXXXX)"
STAGED_APP_PATH="$STAGE_DIR/$APP_NAME.app"
DMG_ROOT="$STAGE_DIR/dmg-root"
CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY:--}"
trap 'rm -rf "$STAGE_DIR"' EXIT

sign_app_bundle() {
  local bundle_path="$1"
  if [ "$CODE_SIGN_IDENTITY" = "-" ]; then
    codesign --force --deep --sign - "$bundle_path"
  else
    codesign --force --deep --options runtime --timestamp --sign "$CODE_SIGN_IDENTITY" "$bundle_path"
  fi
}

clean_app_bundle_distribution_xattrs() {
  local bundle_path="$1"
  xattr -rd com.apple.FinderInfo "$bundle_path" >/dev/null 2>&1 || true
  xattr -rd com.apple.ResourceFork "$bundle_path" >/dev/null 2>&1 || true
  xattr -rd 'com.apple.fileprovider.fpfs#P' "$bundle_path" >/dev/null 2>&1 || true
}

apply_custom_icon() {
  local target_path="$1"
  local icon_path="$2"

  if [ ! -f "$icon_path" ]; then
    return 0
  fi

  if ! /usr/bin/osascript - "$target_path" "$icon_path" <<'OSA' >/dev/null; then
use framework "AppKit"
use scripting additions

on run argv
    set targetPath to item 1 of argv
    set iconPath to item 2 of argv
    set iconImage to current application's NSImage's alloc()'s initWithContentsOfFile:iconPath
    if iconImage is not missing value then
        current application's NSWorkspace's sharedWorkspace()'s setIcon:iconImage forFile:targetPath options:0
    end if
end run
OSA
    echo "Warning: could not apply custom icon to $target_path" >&2
  fi
}

BUILD_CONFIGURATION=release "$ROOT_DIR/script/build_and_run.sh" --build
while IFS= read -r pid; do
  if [ -n "$pid" ]; then
    kill "$pid" >/dev/null 2>&1 || true
  fi
done < <(pgrep -x "SubPulse" || true)

for _ in {1..20}; do
  if ! pgrep -x "SubPulse" >/dev/null 2>&1; then
    break
  fi
  sleep 0.2
done

if [ ! -d "$APP_PATH" ]; then
  echo "App not found at $APP_PATH" >&2
  exit 1
fi

ditto --noextattr --noacl "$APP_PATH" "$STAGED_APP_PATH"
xattr -cr "$STAGED_APP_PATH"
xattr -d com.apple.FinderInfo "$STAGED_APP_PATH" >/dev/null 2>&1 || true
xattr -d com.apple.fileprovider.fpfs#P "$STAGED_APP_PATH" >/dev/null 2>&1 || true
sign_app_bundle "$STAGED_APP_PATH"
codesign --verify --deep --strict --verbose=2 "$STAGED_APP_PATH"

mkdir -p "$DMG_ROOT"
ditto --noextattr --noacl "$STAGED_APP_PATH" "$DMG_ROOT/$APP_NAME.app"
ln -s /Applications "$DMG_ROOT/Applications"
if [ -f "$APP_ICON" ]; then
  cp "$APP_ICON" "$DMG_ROOT/.VolumeIcon.icns"
  /usr/bin/SetFile -a C "$DMG_ROOT" >/dev/null 2>&1 || true
fi
cat > "$DMG_ROOT/Инструкция по установке.txt" <<'TXT'
SubPulse — установка / Installation

1. Перетащите SubPulse.app в папку Applications / Приложения.
2. Запускайте приложение из Applications.

Если macOS блокирует запуск приложения из-за политики Gatekeeper:
1. Откройте Terminal.
2. Выполните команду:
   sudo spctl --master-disable
3. Откройте System Settings -> Privacy & Security и разрешите запуск приложений из любого источника.
4. После установки можно снова включить защиту:
   sudo spctl --master-enable

English

1. Drag SubPulse.app to the Applications folder.
2. Launch SubPulse from Applications.

If macOS blocks the app because of Gatekeeper:
1. Open Terminal.
2. Run:
   sudo spctl --master-disable
3. Open System Settings -> Privacy & Security and allow apps from any source.
4. After installation, you can turn protection back on:
   sudo spctl --master-enable

TXT

hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$DMG_ROOT" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

hdiutil verify "$DMG_PATH" >/dev/null
apply_custom_icon "$DMG_PATH" "$APP_ICON"
clean_app_bundle_distribution_xattrs "$APP_PATH"
if ! codesign --verify --deep --strict --verbose=2 "$APP_PATH"; then
  echo "Warning: local $APP_PATH has Finder metadata. Use the verified DMG for distribution." >&2
fi

echo "DMG created at $DMG_PATH"
