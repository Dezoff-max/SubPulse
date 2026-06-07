import Foundation

enum PaymentCalculator {
    static func occurrences(
        for subscription: Subscription,
        inMonthContaining monthDate: Date,
        calendar: Calendar = .current
    ) -> [PaymentOccurrence] {
        guard subscription.isActive else { return [] }
        let interval = DateUtilities.monthInterval(containing: monthDate, calendar: calendar)
        return occurrenceDates(
            anchor: subscription.billableNextPaymentDate(calendar: calendar),
            period: subscription.billingPeriod,
            interval: interval,
            calendar: calendar
        ).map { PaymentOccurrence(subscription: subscription, date: $0) }
    }

    static func occurrences(
        for subscriptions: [Subscription],
        inMonthContaining monthDate: Date,
        calendar: Calendar = .current
    ) -> [PaymentOccurrence] {
        subscriptions
            .flatMap { occurrences(for: $0, inMonthContaining: monthDate, calendar: calendar) }
            .sorted { $0.date < $1.date }
    }

    static func monthlyTotal(
        for subscriptions: [Subscription],
        monthDate: Date,
        calendar: Calendar = .current
    ) -> Double {
        occurrences(for: subscriptions, inMonthContaining: monthDate, calendar: calendar)
            .reduce(0) { $0 + $1.amount }
    }

    static func monthlyTotal(
        for subscriptions: [Subscription],
        monthDate: Date,
        targetCurrency: String,
        rates: CurrencyRates,
        calendar: Calendar = .current
    ) -> Double {
        occurrences(for: subscriptions, inMonthContaining: monthDate, calendar: calendar)
            .reduce(0) { total, occurrence in
                total + rates.convert(occurrence.amount, from: occurrence.currency, to: targetCurrency)
            }
    }

    static func yearlyForecast(for subscriptions: [Subscription]) -> Double {
        subscriptions
            .filter(\.isActive)
            .reduce(0) { total, subscription in
                total + annualizedAmount(for: subscription)
            }
    }

    static func yearlyForecast(for subscriptions: [Subscription], targetCurrency: String, rates: CurrencyRates) -> Double {
        subscriptions
            .filter(\.isActive)
            .reduce(0) { total, subscription in
                total + annualizedAmount(for: subscription, targetCurrency: targetCurrency, rates: rates)
            }
    }

    static func annualizedAmount(for subscription: Subscription) -> Double {
        guard subscription.isActive else { return 0 }
        return switch subscription.billingPeriod {
        case .weekly: subscription.amount * 52
        case .monthly: subscription.amount * 12
        case .yearly: subscription.amount
        case .custom: subscription.amount
        }
    }

    static func annualizedAmount(for subscription: Subscription, targetCurrency: String, rates: CurrencyRates) -> Double {
        rates.convert(annualizedAmount(for: subscription), from: subscription.currency, to: targetCurrency)
    }

    private static func occurrenceDates(
        anchor: Date,
        period: BillingPeriod,
        interval: DateInterval,
        calendar: Calendar
    ) -> [Date] {
        guard period != .custom else {
            return interval.contains(anchor) ? [anchor] : []
        }

        let component: Calendar.Component
        let step: Int

        switch period {
        case .weekly:
            component = .day
            step = 7
        case .monthly:
            component = .month
            step = 1
        case .yearly:
            component = .year
            step = 1
        case .custom:
            component = .day
            step = 1
        }

        var cursor = anchor

        // nextPaymentDate means the next scheduled charge, not an arbitrary
        // historical recurrence anchor. Never synthesize payments before it,
        // otherwise editing a subscription to a future date appears to "not save"
        // because the current calendar month still shows older generated dates.
        while cursor < interval.start,
              let next = calendar.date(byAdding: component, value: step, to: cursor) {
            cursor = next
        }

        var results: [Date] = []
        while cursor <= interval.end {
            if interval.contains(cursor) || Calendar.current.isDate(cursor, inSameDayAs: interval.end) {
                results.append(cursor)
            }
            guard let next = calendar.date(byAdding: component, value: step, to: cursor) else {
                break
            }
            cursor = next
        }

        return results
    }
}
