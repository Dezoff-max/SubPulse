# CODEX MASTER PROMPT — SubPulse for macOS

Ты — senior macOS developer, SwiftUI architect, product designer, QA engineer и build/release engineer.

Работай как автономный Codex-агент с навыками работы на macOS: Terminal, Finder, Xcode, Git, Swift, SwiftUI, SwiftData, UserNotifications, Charts, Shell scripts, build/release automation.

## Mission

Создай нативное macOS-приложение **SubPulse** для учёта подписок и регулярных платежей.

Приложение должно быть вдохновлено общей идеей календаря подписок, но иметь полностью оригинальные:
- название;
- код;
- структуру проекта;
- UI;
- тексты;
- цвета;
- иконки;
- архитектуру;
- документацию.

Не копируй чужое приложение pixel-perfect. Не используй чужие ассеты, логотипы, proprietary UI или тексты.

---

## Target Platform

- macOS 14+
- Swift
- SwiftUI
- SwiftData
- Charts
- UserNotifications
- AppStorage
- MVVM
- SF Symbols
- Local-first
- No backend in MVP
- No Electron
- No web wrapper
- No third-party dependencies in MVP
- Distribution outside App Store as `.app` and `.dmg`

---

## Required Tools on macOS

Перед началом проверь окружение.

### Required

1. Xcode installed.
2. Xcode Command Line Tools installed.
3. Git installed.
4. Swift compiler available.
5. xcodebuild available.
6. hdiutil available.
7. Project folder created.

### Optional but useful

1. Homebrew.
2. VS Code or Cursor.
3. GitHub CLI.
4. create-dmg or appdmg, only if needed.
5. SwiftLint, only if installed already. Do not require it for MVP.

---

## Environment Check Commands

Выполни в Terminal:

```bash
sw_vers
xcode-select -p
xcodebuild -version
swift --version
git --version
hdiutil help >/dev/null && echo "hdiutil OK"
```

Если Xcode Command Line Tools не настроены, предложи:

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -license accept
```

Если Git не настроен, продолжай локально, но напиши предупреждение.

---

## Working Directory

Создай проект в удобной папке, например:

```bash
mkdir -p ~/Developer/SubPulse
cd ~/Developer/SubPulse
```

Если папка уже существует, не удаляй её без подтверждения. Создай backup или отдельную ветку.

---

## Git Workflow

Инициализируй Git:

```bash
git init
git checkout -b main
```

Создавай коммиты по этапам:

1. initial macOS SwiftUI project
2. add models and SwiftData
3. add dashboard and navigation
4. add subscription editor and list
5. add calendar and recurrence logic
6. add analytics
7. add notifications
8. add settings
9. add docs and dmg script
10. final build fixes

---

## Project Creation

Создай Xcode macOS SwiftUI project.

Требования:

- App name: SubPulse
- Bundle name: SubPulse
- Bundle identifier: com.local.subpulsecalendar
- Interface: SwiftUI
- Language: Swift
- Storage: SwiftData
- Minimum deployment: macOS 14.0

Если невозможно создать `.xcodeproj` автоматически, создай проект через Xcode UI using Computer Use:
1. Open Xcode.
2. File → New → Project.
3. macOS → App.
4. Product Name: SubPulse.
5. Interface: SwiftUI.
6. Language: Swift.
7. Use SwiftData if available.
8. Save to `~/Developer/SubPulse`.

---

## Project Structure

Создай структуру:

```text
SubPulse/
  SubPulseApp.swift

  Models/
    Subscription.swift
    SubscriptionCategory.swift
    PaymentMethod.swift
    AppSettings.swift
    BillingCycle.swift
    PaymentMethodType.swift

  ViewModels/
    DashboardViewModel.swift
    SubscriptionViewModel.swift
    AnalyticsViewModel.swift
    SettingsViewModel.swift
    CalendarViewModel.swift

  Views/
    RootView.swift
    SidebarView.swift
    DashboardView.swift
    CalendarMonthView.swift
    CalendarDayCellView.swift
    SubscriptionListView.swift
    SubscriptionRowView.swift
    SubscriptionEditorView.swift
    AnalyticsView.swift
    SettingsView.swift
    EmptyStateView.swift
    CategoryManagementView.swift
    PaymentMethodManagementView.swift

  Services/
    NotificationService.swift
    SubscriptionCalculator.swift
    DemoDataService.swift
    ExportService.swift

  Utilities/
    Date+Extensions.swift
    CurrencyFormatter.swift
    ColorPalette.swift
    HexColor.swift

  Resources/
    Assets.xcassets

  Docs/
    README.md
    Roadmap.md
    TODO.md

  Scripts/
    build_dmg.sh
```

---

## Core Product Requirements

SubPulse должен позволять пользователю:

1. Добавлять подписку.
2. Редактировать подписку.
3. Удалять подписку.
4. Архивировать / возвращать подписку.
5. Смотреть подписки списком.
6. Смотреть платежи в календаре.
7. Смотреть сумму за месяц.
8. Смотреть прогноз на год.
9. Смотреть расходы по категориям.
10. Получать локальные уведомления.
11. Настраивать валюту.
12. Настраивать категории.
13. Настраивать способы оплаты.
14. Использовать приложение без интернета.

---

## Data Models

### BillingCycle

```swift
enum BillingCycle: String, Codable, CaseIterable, Identifiable {
    case weekly
    case monthly
    case quarterly
    case yearly
    case customDays

    var id: String { rawValue }

    var title: String {
        switch self {
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .quarterly: return "Quarterly"
        case .yearly: return "Yearly"
        case .customDays: return "Custom"
        }
    }
}
```

### PaymentMethodType

```swift
enum PaymentMethodType: String, Codable, CaseIterable, Identifiable {
    case card
    case cash
    case bank
    case applePay
    case paypal
    case other

    var id: String { rawValue }
}
```

### Subscription

SwiftData model with fields:

- id: UUID
- name: String
- amount: Double
- currency: String
- renewalDate: Date
- billingCycle: BillingCycle
- customCycleDays: Int?
- category: SubscriptionCategory?
- paymentMethod: PaymentMethod?
- iconName: String
- colorHex: String
- notes: String
- isActive: Bool
- createdAt: Date
- updatedAt: Date

### SubscriptionCategory

SwiftData model with fields:

- id: UUID
- name: String
- iconName: String
- colorHex: String
- sortOrder: Int

Default categories:

- Productivity
- Utilities
- Entertainment
- Storage
- Finance
- Education
- Health
- Other

### PaymentMethod

SwiftData model with fields:

- id: UUID
- name: String
- type: PaymentMethodType
- lastFourDigits: String?
- colorHex: String
- isDefault: Bool

---

## App Settings

Use AppStorage:

- selectedCurrency
- appearanceMode
- firstReminderDaysBefore
- secondReminderDaysBefore
- reminderHour
- reminderMinute
- hapticFeedback
- showCompactNumbers
- showDecimals
- enableNotifications
- enableDemoData

Appearance values:

- system
- light
- dark

Currencies:

- USD
- EUR
- RUB
- GBP

---

## UI Style

Style name: **Calm Glass Finance**

Rules:

- Native Apple-like macOS UI.
- Soft cards.
- Rounded corners.
- Glass-like panels.
- Subtle gradients.
- Light and dark mode.
- SF Symbols only.
- No brand logos.
- Smooth hover effects.
- Good spacing.
- Clear typography.
- Modern dashboard style.
- Original composition.

---

## Screens

### RootView

Use NavigationSplitView or native sidebar.

Sections:

- Dashboard
- Subscriptions
- Calendar
- Analytics
- Settings

Toolbar:

- Add Subscription
- Search
- Analytics shortcut
- Settings shortcut

Keyboard shortcuts:

- Cmd+N — Add Subscription
- Cmd+F — Search
- Cmd+, — Settings

---

### DashboardView

Show:

- current month
- monthly total
- month status badge
- mini calendar
- active subscription count
- next upcoming payment
- yearly forecast
- average monthly cost
- top category
- add subscription button

Cards:

- Monthly Total
- Active Subscriptions
- Next Payment
- Yearly Forecast
- Average Monthly Cost
- Top Category

---

### CalendarMonthView

Requirements:

- 7 columns.
- Weekday headers.
- Month navigation.
- Highlight today.
- Highlight selected day.
- Show subscription dots/icons.
- Show payments for selected day.
- Support recurring logic:
  - weekly
  - monthly
  - quarterly
  - yearly
  - customDays

---

### SubscriptionListView

Features:

- search by name
- filter by category
- filter by payment method
- sort by renewal date
- sort by amount
- sort by name
- sort by category
- active/archive toggle
- edit action
- delete action
- archive/unarchive action

Row should show:

- icon
- name
- category
- amount
- currency
- renewal date
- billing cycle
- payment method
- active status

---

### SubscriptionEditorView

Sheet/modal for add/edit.

Fields:

- name
- amount
- currency
- renewal date
- billing cycle
- custom cycle days
- category
- payment method
- icon
- color
- notes
- active switch

Validation:

- name required
- amount > 0
- renewal date required
- billing cycle required
- category required
- custom days required if customDays selected

Buttons:

- Save
- Cancel
- Delete if edit mode

---

### AnalyticsView

Use Swift Charts.

Show:

- spending by category
- yearly forecast
- average monthly cost
- most expensive subscription
- upcoming payments
- active subscription count
- category breakdown
- monthly trend placeholder

If donut chart is hard, use bar chart.

---

### SettingsView

Settings:

- Main Currency
- Appearance: System / Light / Dark
- Notifications:
  - enable notifications
  - first reminder
  - second reminder
  - reminder time
  - test notification
- Categories management
- Payment Methods management
- Reset demo data
- Export JSON placeholder
- Import JSON placeholder
- About app

About text:

```text
SubPulse stores your subscription data locally on your Mac. No account or cloud connection is required for the MVP.
```

---

## NotificationService

Use UserNotifications.

Functions:

- requestPermission()
- scheduleReminder(for subscription)
- cancelReminders(for subscription)
- rescheduleReminders(for subscription)
- scheduleTestNotification()

Default reminder:

- 1 day before
- 09:00

Notification title:

```text
Upcoming subscription renewal
```

Body example:

```text
ChatGPT renews tomorrow for $20.00
```

---

## SubscriptionCalculator

Implement:

- totalForMonth
- yearlyForecast
- averageMonthlyCost
- activeSubscriptionCount
- nextUpcomingPayment
- spendingByCategory
- paymentsForDay
- occurrencesForMonth
- occurrencesForYear

Rules:

- Monthly subscriptions repeat every month.
- Yearly subscriptions count only in renewal month.
- Weekly subscriptions count every matching week inside the selected month.
- Quarterly subscriptions count every 3 months from renewal date.
- CustomDays subscriptions repeat every N days.
- Inactive subscriptions are excluded from totals.

---

## Demo Data

Create demo data on first launch if database is empty.

Examples:

- iCloud+
- Google One
- ChatGPT
- Spotify
- Netflix
- Setapp
- Adobe
- YouTube Premium

Do not use official brand logos. Use SF Symbols.

---

## README.md

Create `Docs/README.md` with:

- project description
- features
- tech stack
- how to open in Xcode
- how to run
- how to build Release
- how to build `.dmg`
- notification permissions
- known limitations
- roadmap summary

---

## Roadmap.md

Create `Docs/Roadmap.md` with phases:

1. MVP Core
2. Calendar
3. Calculations
4. Analytics
5. Notifications
6. Settings
7. Import / Export
8. iCloud Sync
9. Localization
10. Pro Features
11. Polish & Release

Each phase must include:
- Goal
- Tasks
- Acceptance Criteria

---

## TODO.md

Create `Docs/TODO.md` with actionable checklist:

- SwiftData migration checks
- recurring logic tests
- unit tests
- iCloud sync
- import/export
- RU/EN localization
- app icon
- code signing
- notarization
- Pro features

---

## Build Script

Create `Scripts/build_dmg.sh`:

```bash
#!/bin/bash
set -e

APP_NAME="SubPulse"
SCHEME="SubPulse"
BUILD_DIR="./build"
DIST_DIR="./dist"

rm -rf "$BUILD_DIR" "$DIST_DIR"
mkdir -p "$DIST_DIR"

xcodebuild \
  -scheme "$SCHEME" \
  -configuration Release \
  -derivedDataPath "$BUILD_DIR"

APP_PATH=$(find "$BUILD_DIR" -name "$APP_NAME.app" -type d | head -n 1)

if [ -z "$APP_PATH" ]; then
  echo "App not found"
  exit 1
fi

cp -R "$APP_PATH" "$DIST_DIR/"

hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$DIST_DIR/$APP_NAME.app" \
  -ov \
  -format UDZO \
  "$DIST_DIR/$APP_NAME.dmg"

echo "DMG created at $DIST_DIR/$APP_NAME.dmg"
```

Then run:

```bash
chmod +x Scripts/build_dmg.sh
```

---

## Build and QA Steps

After implementation:

```bash
xcodebuild -scheme SubPulse -configuration Debug build
```

If errors appear:
1. Read the error.
2. Fix the code.
3. Build again.
4. Repeat until successful.

Then run Release build:

```bash
xcodebuild -scheme SubPulse -configuration Release build
```

Then test DMG:

```bash
./Scripts/build_dmg.sh
```

---

## Manual QA Checklist

Verify:

- app launches
- sidebar works
- dashboard opens
- adding subscription works
- editing subscription works
- deleting subscription works
- archive/unarchive works
- data persists after restart
- calendar shows payments
- analytics shows demo data
- settings open
- notification permission does not crash
- test notification works
- light mode readable
- dark mode readable
- small window layout does not break
- README exists
- Roadmap exists
- TODO exists
- build_dmg.sh exists

---

## Final Report

When finished, provide:

1. Project location.
2. Files created.
3. Commands used.
4. Build status.
5. Features completed.
6. Known limitations.
7. How to open in Xcode.
8. How to build `.app`.
9. How to build `.dmg`.
10. What to do next.

Do not stop after creating files. Build the project and fix compile errors.
