# SubPulse

SubPulse is a native macOS 14+ SwiftUI app for tracking subscriptions, recurring payments, renewal dates, categories, payment methods, reminders, and spending analytics.

Landing page: https://subpulse.netlify.app

## Tech Stack

- Swift, SwiftUI, SwiftData
- Charts
- UserNotifications
- MVVM-oriented view models
- SF Symbols
- Local SwiftData storage
- Network access only for optional CBR exchange-rate refresh
- Export/restore JSON backups

## Landing Page

The `landing/` folder contains a Vite + React landing page deployed to Netlify:

```text
https://subpulse.netlify.app
```

The landing page includes Netlify Functions and Netlify Blobs counters for downloads, online visitors, and total visitors.

## Open in Xcode

1. Open Xcode 15 or newer.
2. Choose `File > Open...`.
3. Select this folder or `Package.swift`.
4. Select the `SubPulse` executable target.
5. Press `Cmd + R`.

## Build and Run Locally

```bash
./script/build_and_run.sh
```

The script builds with SwiftPM, stages a foreground app bundle, and launches:

```text
dist/SubPulse.app
```

Verification mode:

```bash
./script/build_and_run.sh --verify
```

## Build `.app`

```bash
swift build -c release
./script/build_and_run.sh
```

The resulting app bundle is placed at:

```text
dist/SubPulse.app
```

## Create `.dmg`

```bash
./build_dmg.sh
```

The DMG is placed at:

```text
dist/SubPulse.dmg
```

For personal distribution outside the App Store, sign and notarize before sharing publicly.

## Backup Data

Open `Settings > Data` and use:

- `Export Backup` to save subscriptions, categories and payment methods to JSON.
- `Restore Backup` to replace local data with a backup file.

Store backups outside the app folder before resetting data or moving to another Mac.

## Developer ID Signing and Notarization

Local development uses ad-hoc signing. To share SubPulse with other Macs without Gatekeeper warnings, install a Developer ID Application certificate and run:

```bash
CODE_SIGN_IDENTITY='Developer ID Application: Your Name (TEAMID)' ./build_dmg.sh
```

To notarize:

```bash
xcrun notarytool store-credentials subpulse-notary \
  --apple-id YOUR_APPLE_ID \
  --team-id TEAM_ID \
  --password APP_SPECIFIC_PASSWORD

CODE_SIGN_IDENTITY='Developer ID Application: Your Name (TEAMID)' \
NOTARY_PROFILE='subpulse-notary' \
./script/notarize_dmg.sh
```

See `ReleaseChecklist.md` for the full release flow.

Final local audit:

```bash
./script/release_audit.sh
```

The audit runs tests, builds the app, verifies the app bundle, creates and verifies the DMG, checks DMG contents, and reports whether a Developer ID Application certificate is installed.

## Privacy Notes

SubPulse stores subscription data locally. It only uses network access for optional public CBR exchange-rate refreshes and can request Reminders/Notifications permissions for local reminders.

See `PrivacyPolicy.md` before publishing or sharing a build broadly.
