#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
PRODUCT_NAME="SubPulse"
APP_NAME="SubPulse"
BUNDLE_ID="com.subpulse.app"
MIN_SYSTEM_VERSION="14.0"
APP_VERSION="${APP_VERSION:-0.2.0}"
BUILD_CONFIGURATION="${BUILD_CONFIGURATION:-debug}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_BINARY="$APP_MACOS/$PRODUCT_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
APP_ICON="$ROOT_DIR/Resources/AppIcon.icns"
BUILD_NUMBER_FILE="${BUILD_NUMBER_FILE:-$ROOT_DIR/.build/subpulse-build-number}"
CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY:--}"

clean_bundle_xattrs() {
  local bundle_path="$1"
  for _ in 1 2 3; do
    xattr -rd com.apple.fileprovider.fpfs#P "$bundle_path" >/dev/null 2>&1 || true
    xattr -rd com.apple.FinderInfo "$bundle_path" >/dev/null 2>&1 || true
  done
}

sign_app_bundle() {
  local bundle_path="$1"
  if [ "$CODE_SIGN_IDENTITY" = "-" ]; then
    codesign --force --deep --sign - "$bundle_path"
  else
    codesign --force --deep --options runtime --timestamp --sign "$CODE_SIGN_IDENTITY" "$bundle_path"
  fi
}

if [ -z "${APP_BUILD:-}" ]; then
  previous_build="0"
  if [ -f "$BUILD_NUMBER_FILE" ]; then
    previous_build="$(cat "$BUILD_NUMBER_FILE")"
  elif [ -f "$INFO_PLIST" ]; then
    previous_build="$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$INFO_PLIST" 2>/dev/null || echo "0")"
  fi

  if ! [[ "$previous_build" =~ ^[0-9]+$ ]]; then
    previous_build="0"
  fi

  APP_BUILD="$((previous_build + 1))"
  mkdir -p "$(dirname "$BUILD_NUMBER_FILE")"
  printf '%s\n' "$APP_BUILD" > "$BUILD_NUMBER_FILE"
fi

while IFS= read -r pid; do
  if [ -n "$pid" ]; then
    kill "$pid" >/dev/null 2>&1 || true
  fi
done < <(pgrep -x "$PRODUCT_NAME" || true)

swift build -c "$BUILD_CONFIGURATION"
BUILD_BINARY="$(swift build -c "$BUILD_CONFIGURATION" --show-bin-path)/$PRODUCT_NAME"

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS" "$APP_RESOURCES"
cp "$BUILD_BINARY" "$APP_BINARY"
chmod +x "$APP_BINARY"
if [ -f "$APP_ICON" ]; then
  cp "$APP_ICON" "$APP_RESOURCES/AppIcon.icns"
fi

/usr/libexec/PlistBuddy -c "Clear dict" "$INFO_PLIST" >/dev/null 2>&1 || true
/usr/libexec/PlistBuddy -c "Add :CFBundleExecutable string $PRODUCT_NAME" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string $BUNDLE_ID" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleName string $APP_NAME" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string $APP_VERSION" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleVersion string $APP_BUILD" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string AppIcon" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundlePackageType string APPL" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :LSMinimumSystemVersion string $MIN_SYSTEM_VERSION" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :NSPrincipalClass string NSApplication" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :NSRemindersUsageDescription string SubPulse syncs subscription renewal tasks with Reminders." "$INFO_PLIST"

xattr -cr "$APP_BUNDLE"
xattr -d com.apple.FinderInfo "$APP_BUNDLE" >/dev/null 2>&1 || true
xattr -d com.apple.fileprovider.fpfs#P "$APP_BUNDLE" >/dev/null 2>&1 || true

SIGNING_DIR="$(mktemp -d /tmp/subpulse-sign.XXXXXX)"
SIGNED_APP_BUNDLE="$SIGNING_DIR/$APP_NAME.app"
ditto --norsrc --noextattr --noacl "$APP_BUNDLE" "$SIGNED_APP_BUNDLE"
xattr -cr "$SIGNED_APP_BUNDLE"
xattr -d com.apple.FinderInfo "$SIGNED_APP_BUNDLE" >/dev/null 2>&1 || true
xattr -d com.apple.fileprovider.fpfs#P "$SIGNED_APP_BUNDLE" >/dev/null 2>&1 || true
sign_app_bundle "$SIGNED_APP_BUNDLE"
rm -rf "$APP_BUNDLE"
ditto --norsrc --noextattr --noacl "$SIGNED_APP_BUNDLE" "$APP_BUNDLE"
rm -rf "$SIGNING_DIR"
clean_bundle_xattrs "$APP_BUNDLE"
codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"
echo "Built $APP_NAME $APP_VERSION ($APP_BUILD)"

open_app() {
  /usr/bin/open -n "$APP_BUNDLE"
}

verify_running() {
  pgrep -x "$PRODUCT_NAME" >/dev/null
}

case "$MODE" in
  --build|build)
    ;;
  run)
    open_app
    ;;
  --debug|debug)
    lldb -- "$APP_BINARY"
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$PRODUCT_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify|verify)
    open_app
    sleep 2
    verify_running
    while IFS= read -r pid; do
      if [ -n "$pid" ]; then
        kill "$pid" >/dev/null 2>&1 || true
      fi
    done < <(pgrep -x "$PRODUCT_NAME" || true)
    for _ in {1..20}; do
      if ! pgrep -x "$PRODUCT_NAME" >/dev/null 2>&1; then
        break
      fi
      sleep 0.2
    done
    clean_bundle_xattrs "$APP_BUNDLE"
    codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"
    ;;
  *)
    echo "usage: $0 [run|--build|--debug|--logs|--telemetry|--verify]" >&2
    exit 2
    ;;
esac
