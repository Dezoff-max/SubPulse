# Roadmap — SubPulse

SubPulse is a native macOS application for tracking subscriptions, recurring payments, renewal dates, payment methods, categories, reminders, and spending analytics.

The app is local-first, privacy-friendly, and designed for distribution outside the App Store as `.app` and `.dmg`.

---

## Phase 1 — MVP Core

### Goal

Create a working native macOS application for local subscription tracking.

### Tasks

- [ ] Create Xcode macOS SwiftUI project
- [ ] Configure SwiftData
- [ ] Create Subscription model
- [ ] Create SubscriptionCategory model
- [ ] Create PaymentMethod model
- [ ] Create BillingCycle enum
- [ ] Create PaymentMethodType enum
- [ ] Create RootView
- [ ] Create SidebarView
- [ ] Create DashboardView
- [ ] Create SubscriptionListView
- [ ] Create SubscriptionEditorView
- [ ] Add subscription creation
- [ ] Add subscription editing
- [ ] Add subscription deletion
- [ ] Add archive/unarchive logic
- [ ] Add demo data
- [ ] Verify data persistence after restart

### Acceptance Criteria

- User can launch the app.
- User can add a subscription.
- User can edit a subscription.
- User can delete a subscription.
- User can see subscriptions after app restart.
- App builds without errors.

---

## Phase 2 — Calendar

### Goal

Create a visual calendar for subscription renewal dates.

### Tasks

- [ ] Create CalendarMonthView
- [ ] Create CalendarDayCellView
- [ ] Add month navigation
- [ ] Show weekday headers
- [ ] Highlight today
- [ ] Highlight selected day
- [ ] Show subscription dots/icons on renewal dates
- [ ] Show payment list for selected day
- [ ] Support weekly subscriptions
- [ ] Support monthly subscriptions
- [ ] Support quarterly subscriptions
- [ ] Support yearly subscriptions
- [ ] Support custom day cycle subscriptions

### Acceptance Criteria

- Calendar displays the selected month correctly.
- Renewal dates are visible in day cells.
- Clicking a day shows payments for that day.
- Recurring payments are calculated correctly.

---

## Phase 3 — Calculations

### Goal

Create accurate subscription calculations.

### Tasks

- [ ] Create SubscriptionCalculator service
- [ ] Calculate total monthly spend
- [ ] Calculate yearly forecast
- [ ] Calculate average monthly cost
- [ ] Calculate active subscription count
- [ ] Calculate next upcoming payment
- [ ] Calculate spending by category
- [ ] Calculate payments for selected day
- [ ] Calculate monthly occurrences
- [ ] Calculate yearly occurrences
- [ ] Handle inactive subscriptions correctly

### Acceptance Criteria

- Dashboard total is correct.
- Yearly forecast is correct.
- Category breakdown is correct.
- Upcoming payment is correct.
- Inactive subscriptions do not affect totals.

---

## Phase 4 — Analytics

### Goal

Create useful financial analytics.

### Tasks

- [ ] Create AnalyticsView
- [ ] Add spending by category chart
- [ ] Add yearly forecast card
- [ ] Add average monthly cost card
- [ ] Add most expensive subscription card
- [ ] Add upcoming payments list
- [ ] Add active subscription count
- [ ] Add category filter
- [ ] Add year filter
- [ ] Add empty states

### Acceptance Criteria

- Analytics screen shows useful data.
- Charts work with demo data.
- Empty state appears when there are no subscriptions.
- Dark mode contrast is readable.

---

## Phase 5 — Notifications

### Goal

Add local renewal reminders.

### Tasks

- [ ] Create NotificationService
- [ ] Request notification permission
- [ ] Add first reminder setting
- [ ] Add second reminder setting
- [ ] Add reminder time setting
- [ ] Add test notification
- [ ] Schedule notifications for active subscriptions
- [ ] Cancel old notifications after subscription edit
- [ ] Cancel notifications after subscription deletion
- [ ] Reschedule notifications after app launch

### Acceptance Criteria

- User can enable notifications.
- Test notification works.
- Reminder notifications are scheduled.
- Editing subscription updates notification schedule.
- Deleting subscription removes notifications.

---

## Phase 6 — Settings

### Goal

Create full application settings.

### Tasks

- [ ] Create SettingsView
- [ ] Add main currency setting
- [ ] Add appearance setting
- [ ] Add notification settings
- [ ] Add category management
- [ ] Add payment method management
- [ ] Add demo data reset
- [ ] Add import/export placeholders
- [ ] Add About section
- [ ] Add version display

### Acceptance Criteria

- Settings are saved.
- Appearance mode works.
- Currency setting is used in the UI.
- Notification settings affect scheduling.

---

## Phase 7 — Import / Export

### Goal

Give users control over their data.

### Tasks

- [ ] Add JSON export
- [ ] Add JSON import
- [ ] Add CSV export
- [ ] Add backup file
- [ ] Add restore from backup
- [ ] Validate import data
- [ ] Handle import errors gracefully

### Acceptance Criteria

- User can export data.
- User can import data.
- Invalid import files do not crash the app.

---

## Phase 8 — iCloud Sync

### Goal

Add optional sync between Apple devices.

### Tasks

- [ ] Research SwiftData + CloudKit
- [ ] Add CloudKit container
- [ ] Add iCloud sync setting
- [ ] Add local-only mode
- [ ] Handle sync conflicts
- [ ] Test on multiple Macs

### Acceptance Criteria

- User can enable iCloud sync.
- Data syncs between devices.
- App still works without iCloud.

---

## Phase 9 — Localization

### Goal

Prepare app for English and Russian users.

### Tasks

- [ ] Add localization structure
- [ ] Add English strings
- [ ] Add Russian strings
- [ ] Localize dates
- [ ] Localize currencies
- [ ] Localize notification text
- [ ] Localize README partially

### Acceptance Criteria

- App can switch between English and Russian based on system language.
- UI remains readable in both languages.

---

## Phase 10 — Pro Features

### Goal

Prepare future monetization.

### Tasks

- [ ] Add StoreKit 2 architecture placeholder
- [ ] Add Free limit placeholder
- [ ] Add Lifetime license placeholder
- [ ] Add Upgrade screen placeholder
- [ ] Add restore purchases placeholder
- [ ] Add unlock logic placeholder

### Possible Free Plan

- Up to 3 subscriptions
- Basic calendar
- Basic analytics

### Possible Pro Plan

- Unlimited subscriptions
- iCloud sync
- Import/export
- Advanced analytics
- Custom categories
- Custom icons
- Extra widgets

### Acceptance Criteria

- MVP does not require purchases.
- Architecture allows adding Pro features later.

---

## Phase 11 — Polish & Release

### Goal

Prepare the app for distribution outside the App Store.

### Tasks

- [ ] Create app icon
- [ ] Improve light mode
- [ ] Improve dark mode
- [ ] Improve empty states
- [ ] Improve small window layout
- [ ] Add keyboard shortcuts
- [ ] Add menu commands
- [ ] Add release build script
- [ ] Add DMG build script
- [ ] Add code signing instructions
- [ ] Add notarization instructions
- [ ] Test on Apple Silicon
- [ ] Test on Intel Mac if possible

### Acceptance Criteria

- Release build works.
- `.app` can be launched.
- `.dmg` can be created.
- README explains distribution.
