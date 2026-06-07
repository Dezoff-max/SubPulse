# SubPulse

SubPulse is a native macOS application for tracking subscriptions, recurring payments, renewal dates, categories, payment methods, reminders, and spending analytics.

The app is designed as a local-first privacy-friendly macOS app that can be distributed outside the App Store as `.app` or `.dmg`.

## Main Features

- Subscription tracking
- Calendar-based renewal view
- Monthly total
- Yearly forecast
- Average monthly cost
- Spending by category
- Upcoming payments
- Local reminders
- Categories
- Payment methods
- Light / dark / system appearance
- Local SwiftData storage
- Demo data on first launch

## Tech Stack

- Swift
- SwiftUI
- SwiftData
- Charts
- UserNotifications
- AppStorage
- MVVM
- SF Symbols
- macOS 14+

## Privacy

SubPulse stores your subscription data locally on your Mac. No account or cloud connection is required for the MVP.

## How to Open

1. Open Xcode.
2. Choose `Open Existing Project`.
3. Select the `SubPulse.xcodeproj` file.
4. Choose the `SubPulse` scheme.
5. Press `Cmd + R` to run.

## How to Build Release

```bash
xcodebuild \
  -scheme SubPulse \
  -configuration Release \
  -derivedDataPath ./build
```

## How to Create DMG

Run:

```bash
chmod +x Scripts/build_dmg.sh
./Scripts/build_dmg.sh
```

The final DMG should appear in:

```text
dist/SubPulse.dmg
```

## Known Limitations in MVP

- No iCloud sync yet
- No import/export yet
- No StoreKit purchases yet
- No official brand logos
- Landing page backend is limited to Netlify Functions counters
- No multi-device sync

## Future Roadmap

See `Docs/Roadmap.md`.
