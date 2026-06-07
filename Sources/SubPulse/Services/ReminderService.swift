import AppKit
import EventKit
import Foundation

@MainActor
final class ReminderService: ObservableObject {
    static let shared = ReminderService()

    @Published private(set) var isSyncing = false
    @Published private(set) var lastSyncStatus: String?

    private let eventStore = EKEventStore()
    private let calendarTitle = "SubPulse"
    private let markerPrefix = "[SubPulse:"

    private init() {}

    func sync(
        subscriptions: [Subscription],
        firstDaysBefore: Int,
        secondDaysBefore: Int,
        language: String
    ) async {
        isSyncing = true
        defer { isSyncing = false }

        do {
            guard try await requestAccess() else {
                lastSyncStatus = L10n.text("remindersAccessDenied", language: language)
                return
            }

            let calendar = try remindersCalendar()
            let existing = await reminders(in: calendar)
            let activeSubscriptions = subscriptions.filter(\.isActive)
            let activeIDs = Set(activeSubscriptions.map(\.id.uuidString))

            for reminder in existing {
                guard let id = subscriptionID(in: reminder), !activeIDs.contains(id) else { continue }
                try eventStore.remove(reminder, commit: false)
            }

            for subscription in activeSubscriptions {
                let reminder = existing.first { subscriptionID(in: $0) == subscription.id.uuidString }
                    ?? EKReminder(eventStore: eventStore)
                configure(
                    reminder,
                    for: subscription,
                    calendar: calendar,
                    firstDaysBefore: firstDaysBefore,
                    secondDaysBefore: secondDaysBefore,
                    language: language
                )
                try eventStore.save(reminder, commit: false)
            }

            try eventStore.commit()
            lastSyncStatus = String(
                format: L10n.text("remindersSyncDone", language: language),
                activeSubscriptions.count
            )
        } catch {
            lastSyncStatus = L10n.text("remindersSyncFailed", language: language)
        }
    }

    func openRemindersApp() {
        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Reminders.app"))
    }

    func deleteSubPulseReminders(language: String) async {
        isSyncing = true
        defer { isSyncing = false }

        do {
            guard try await requestAccess() else {
                lastSyncStatus = L10n.text("remindersAccessDenied", language: language)
                return
            }

            guard let calendar = eventStore.calendars(for: .reminder).first(where: { $0.title == calendarTitle }) else {
                return
            }

            let existing = await reminders(in: calendar)
            for reminder in existing {
                try eventStore.remove(reminder, commit: false)
            }

            try eventStore.commit()
            lastSyncStatus = L10n.text("remindersResetDone", language: language)
        } catch {
            lastSyncStatus = L10n.text("remindersSyncFailed", language: language)
        }
    }

    private func requestAccess() async throws -> Bool {
        try await eventStore.requestFullAccessToReminders()
    }

    private func remindersCalendar() throws -> EKCalendar {
        let calendars = eventStore.calendars(for: .reminder)
        if let existing = calendars.first(where: { $0.title == calendarTitle }) {
            return existing
        }

        guard let source = eventStore.defaultCalendarForNewReminders()?.source ?? eventStore.sources.first else {
            throw ReminderServiceError.missingSource
        }

        let calendar = EKCalendar(for: .reminder, eventStore: eventStore)
        calendar.title = calendarTitle
        calendar.source = source
        try eventStore.saveCalendar(calendar, commit: true)
        return calendar
    }

    private func reminders(in calendar: EKCalendar) async -> [EKReminder] {
        let predicate = eventStore.predicateForReminders(in: [calendar])
        return await withCheckedContinuation { continuation in
            eventStore.fetchReminders(matching: predicate) { reminders in
                continuation.resume(returning: reminders ?? [])
            }
        }
    }

    private func configure(
        _ reminder: EKReminder,
        for subscription: Subscription,
        calendar: EKCalendar,
        firstDaysBefore: Int,
        secondDaysBefore: Int,
        language: String
    ) {
        let paymentDate = nextUpcomingPaymentDate(for: subscription) ?? subscription.nextPaymentDate
        let dueDate = Calendar.current.startOfDay(for: paymentDate)

        reminder.calendar = calendar
        reminder.title = reminderTitle(for: subscription, language: language)
        reminder.notes = reminderNotes(for: subscription, paymentDate: paymentDate, language: language)
        reminder.priority = 5
        reminder.isCompleted = false
        reminder.dueDateComponents = Calendar.current.dateComponents([.year, .month, .day], from: dueDate)
        reminder.alarms = reminderAlarms(for: dueDate, firstDaysBefore: firstDaysBefore, secondDaysBefore: secondDaysBefore)
        reminder.recurrenceRules = recurrenceRules(for: subscription.billingPeriod)
    }

    private func reminderTitle(for subscription: Subscription, language: String) -> String {
        let resolved = AppLanguage(rawValue: language) ?? .system
        if resolved.resolvedCode == "ru" {
            return "Оплатить \(subscription.name)"
        }
        return "Pay \(subscription.name)"
    }

    private func reminderNotes(for subscription: Subscription, paymentDate: Date, language: String) -> String {
        let amount = MoneyFormatter.string(subscription.amount, currency: subscription.currency)
        let date = L10n.shortDate(paymentDate, language: language)
        let marker = "\(markerPrefix)\(subscription.id.uuidString)]"
        let resolved = AppLanguage(rawValue: language) ?? .system

        if resolved.resolvedCode == "ru" {
            return "\(marker)\nСумма: \(amount)\nДата списания: \(date)\nСоздано SubPulse."
        }
        return "\(marker)\nAmount: \(amount)\nPayment date: \(date)\nCreated by SubPulse."
    }

    private func reminderAlarms(for dueDate: Date, firstDaysBefore: Int, secondDaysBefore: Int) -> [EKAlarm] {
        let days = Set([firstDaysBefore, secondDaysBefore]).sorted()
        return days.compactMap { daysBefore in
            Calendar.current.date(byAdding: .day, value: -daysBefore, to: dueDate)
        }
        .filter { $0 > Date() }
        .map { EKAlarm(absoluteDate: $0) }
    }

    private func recurrenceRules(for period: BillingPeriod) -> [EKRecurrenceRule]? {
        let frequency: EKRecurrenceFrequency
        switch period {
        case .weekly:
            frequency = .weekly
        case .monthly:
            frequency = .monthly
        case .yearly:
            frequency = .yearly
        case .custom:
            return nil
        }

        return [EKRecurrenceRule(recurrenceWith: frequency, interval: 1, end: nil)]
    }

    private func subscriptionID(in reminder: EKReminder) -> String? {
        guard let notes = reminder.notes,
              let markerStart = notes.range(of: markerPrefix),
              let markerEnd = notes[markerStart.upperBound...].firstIndex(of: "]")
        else {
            return nil
        }
        return String(notes[markerStart.upperBound..<markerEnd])
    }

    private func nextUpcomingPaymentDate(for subscription: Subscription) -> Date? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var candidate = calendar.startOfDay(for: subscription.billableNextPaymentDate(calendar: calendar))
        guard subscription.billingPeriod != .custom || candidate >= today else { return nil }

        let component: Calendar.Component
        let value: Int
        switch subscription.billingPeriod {
        case .weekly:
            component = .day
            value = 7
        case .monthly:
            component = .month
            value = 1
        case .yearly:
            component = .year
            value = 1
        case .custom:
            return candidate
        }

        while candidate < today {
            guard let next = calendar.date(byAdding: component, value: value, to: candidate) else {
                return nil
            }
            candidate = next
        }

        return candidate
    }
}

private enum ReminderServiceError: Error {
    case missingSource
}
