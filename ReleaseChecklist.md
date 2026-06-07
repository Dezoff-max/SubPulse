# SubPulse Release Checklist

Use this checklist before sharing SubPulse outside your own Mac.

## 1. Version

- Set the marketing version if needed:

```bash
APP_VERSION=0.2.0 ./script/build_and_run.sh --build
```

- The build number increases automatically in `.build/subpulse-build-number`.
- Verify `Info.plist`:

```bash
/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' dist/SubPulse.app/Contents/Info.plist
/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' dist/SubPulse.app/Contents/Info.plist
```

## 2. Local Validation

Run the complete local audit:

```bash
./script/release_audit.sh
```

Or run the individual checks:

```bash
swift build
swift build -c release
swift test
./script/build_and_run.sh --verify
./build_dmg.sh
hdiutil verify dist/SubPulse.dmg
codesign --verify --deep --strict --verbose=2 dist/SubPulse.app
```

The test target covers payment recurrences, analytics periods, currency conversion and backup restore.

## 3. Developer ID Signing

Install a Developer ID Application certificate, then find the exact identity:

```bash
security find-identity -p codesigning -v
```

Build a signed DMG:

```bash
CODE_SIGN_IDENTITY='Developer ID Application: Your Name (TEAMID)' ./build_dmg.sh
```

This enables hardened runtime through `codesign --options runtime --timestamp`.

## 4. Notarization

Create a notarytool keychain profile once:

```bash
xcrun notarytool store-credentials subpulse-notary \
  --apple-id YOUR_APPLE_ID \
  --team-id TEAM_ID \
  --password APP_SPECIFIC_PASSWORD
```

Submit, staple and validate:

```bash
CODE_SIGN_IDENTITY='Developer ID Application: Your Name (TEAMID)' \
NOTARY_PROFILE='subpulse-notary' \
./script/notarize_dmg.sh
```

Expected final checks:

```bash
xcrun stapler validate dist/SubPulse.dmg
spctl -a -vvv -t open --context context:primary-signature dist/SubPulse.dmg
```

## 5. Data Safety

- Open Settings and use `Export Backup`.
- Store the JSON backup outside the app folder.
- Test `Restore Backup` on a copy of the data before releasing a build that changes models.

## 6. Known Release Gaps

- Review `PrivacyPolicy.md` before publishing. It explains local SwiftData storage, optional CBR exchange-rate requests, and Reminders/Notifications permissions.
- Keep import copy honest: current implementation imports screenshots/text with local OCR, not private system receipt data.
- Replace ad-hoc signing with Developer ID signing before sending the app to another Mac.
