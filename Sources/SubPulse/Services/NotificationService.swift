import Foundation
import UserNotifications

@MainActor
final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func scheduleReminders(
        for subscriptions: [Subscription],
        firstDaysBefore: Int,
        secondDaysBefore: Int,
        language: String
    ) async {
        let granted = await requestAuthorization()
        guard granted else { return }

        for subscription in subscriptions {
            cancelReminders(for: subscription)
            guard subscription.isActive else { continue }
            await scheduleReminder(
                for: subscription,
                daysBefore: firstDaysBefore,
                slot: "first",
                language: language,
                requiresAuthorization: false
            )

            if secondDaysBefore != firstDaysBefore {
                await scheduleReminder(
                    for: subscription,
                    daysBefore: secondDaysBefore,
                    slot: "second",
                    language: language,
                    requiresAuthorization: false
                )
            }
        }
    }

    func scheduleReminders(
        for subscription: Subscription,
        firstDaysBefore: Int,
        secondDaysBefore: Int,
        language: String
    ) async {
        await scheduleReminders(
            for: [subscription],
            firstDaysBefore: firstDaysBefore,
            secondDaysBefore: secondDaysBefore,
            language: language
        )
    }

    func scheduleReminder(for subscription: Subscription, daysBefore: Int = 1) async {
        await scheduleReminder(
            for: subscription,
            daysBefore: daysBefore,
            slot: "single",
            language: AppLanguage.system.rawValue,
            requiresAuthorization: true
        )
    }

    private func scheduleReminder(
        for subscription: Subscription,
        daysBefore: Int,
        slot: String,
        language: String,
        requiresAuthorization: Bool
    ) async {
        guard subscription.isActive else { return }
        if requiresAuthorization {
            let granted = await requestAuthorization()
            guard granted else { return }
        }

        guard let paymentDate = nextUpcomingPaymentDate(for: subscription),
              let triggerDate = Calendar.current.date(byAdding: .day, value: -daysBefore, to: paymentDate),
              triggerDate > Date()
        else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = notificationTitle(for: subscription, daysBefore: daysBefore, language: language)
        content.body = notificationBody(for: subscription, paymentDate: paymentDate, language: language)
        content.sound = .default
        content.badge = 1

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: reminderIdentifier(for: subscription, slot: slot),
            content: content,
            trigger: trigger
        )

        try? await UNUserNotificationCenter.current().add(request)
    }

    func sendTestNotification(language: String = AppLanguage.system.rawValue) async {
        let granted = await requestAuthorization()
        guard granted else { return }

        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["subpulse.test"])

        let content = UNMutableNotificationContent()
        content.title = "SubPulse"
        content.body = L10n.text("notificationsReady", language: language)
        content.sound = .default
        content.badge = 1

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "subpulse.test", content: content, trigger: trigger)
        try? await UNUserNotificationCenter.current().add(request)
    }

    func cancelReminders(for subscription: Subscription) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [
                reminderIdentifier(for: subscription, slot: "single"),
                reminderIdentifier(for: subscription, slot: "first"),
                reminderIdentifier(for: subscription, slot: "second")
            ]
        )
    }

    private func reminderIdentifier(for subscription: Subscription, slot: String) -> String {
        "subpulse.subscription.\(subscription.id.uuidString).\(slot)"
    }

    private func notificationTitle(for subscription: Subscription, daysBefore: Int, language: String) -> String {
        let resolved = AppLanguage(rawValue: language) ?? .system
        if resolved.resolvedCode == "ru" {
            if daysBefore == 0 {
                return "\(subscription.name): платеж сегодня"
            }
            return "\(subscription.name): платеж через \(daysBefore) \(russianDayWord(daysBefore))"
        }

        if daysBefore == 0 {
            return "\(subscription.name) renews today"
        }
        return "\(subscription.name) renews in \(daysBefore) \(daysBefore == 1 ? "day" : "days")"
    }

    private func notificationBody(for subscription: Subscription, paymentDate: Date, language: String) -> String {
        let resolved = AppLanguage(rawValue: language) ?? .system
        let amount = MoneyFormatter.string(subscription.amount, currency: subscription.currency)
        let date = L10n.shortDate(paymentDate, language: language)
        if resolved.resolvedCode == "ru" {
            return "Списание \(amount) запланировано на \(date)."
        }
        return "Upcoming payment of \(amount) on \(date)."
    }

    private func russianDayWord(_ count: Int) -> String {
        let lastTwo = count % 100
        let last = count % 10
        if (11...14).contains(lastTwo) { return "дней" }
        if last == 1 { return "день" }
        if (2...4).contains(last) { return "дня" }
        return "дней"
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

        // Users can keep old subscriptions around. For reminders, advance the
        // recurrence anchor until it points to the next real future payment.
        while candidate < today {
            guard let next = calendar.date(byAdding: component, value: value, to: candidate) else {
                return nil
            }
            candidate = next
        }

        return candidate
    }
}

extension NotificationService {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound, .badge]
    }
}
