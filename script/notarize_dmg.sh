#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="SubPulse"
DMG_PATH="$ROOT_DIR/dist/$APP_NAME.dmg"

if [ -z "${CODE_SIGN_IDENTITY:-}" ]; then
  echo "Set CODE_SIGN_IDENTITY to your Developer ID Application identity." >&2
  echo "Example: CODE_SIGN_IDENTITY='Developer ID Application: Your Name (TEAMID)' $0" >&2
  exit 2
fi

if [ -z "${NOTARY_PROFILE:-}" ]; then
  echo "Set NOTARY_PROFILE to an xcrun notarytool keychain profile." >&2
  echo "Create one with: xcrun notarytool store-credentials subpulse-notary --apple-id APPLE_ID --team-id TEAM_ID --password APP_SPECIFIC_PASSWORD" >&2
  exit 2
fi

CODE_SIGN_IDENTITY="$CODE_SIGN_IDENTITY" "$ROOT_DIR/build_dmg.sh"

xcrun notarytool submit "$DMG_PATH" \
  --keychain-profile "$NOTARY_PROFILE" \
  --wait

xcrun stapler staple "$DMG_PATH"
xcrun stapler validate "$DMG_PATH"
spctl -a -vvv -t open --context context:primary-signature "$DMG_PATH"

echo "Notarized DMG ready at $DMG_PATH"
