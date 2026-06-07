import Foundation
import Observation

struct CategorySpend: Identifiable {
    let id = UUID()
    let name: String
    let amount: Double
    let colorHex: String
}

struct MonthlySpend: Identifiable {
    let id = UUID()
    let month: Date
    let amount: Double
}

enum AnalyticsPeriod: String, CaseIterable, Identifiable {
    case month
    case sixMonths
    case year

    var id: String { rawValue }

    var monthCount: Int {
        switch self {
        case .month: 1
        case .sixMonths: 6
        case .year: 12
        }
    }

    func localizedTitle(language: String) -> String {
        switch self {
        case .month:
            L10n.text("periodOneMonth", language: language)
        case .sixMonths:
            L10n.text("periodSixMonths", language: language)
        case .year:
            L10n.text("periodOneYear", language: language)
        }
    }
}

struct SubscriptionSpend: Identifiable {
    let id: UUID
    let name: String
    let iconName: String
    let categoryName: String
    let colorHex: String
    let amount: Double
}

struct UpcomingSpendWindow: Identifiable {
    let id: Int
    let days: Int
    let amount: Double
    let count: Int
}

struct GrowthSnapshot {
    let currentPeriod: Double
    let previousPeriod: Double
    let difference: Double
    let differencePercent: Double?
    let newImpact: Double
    let newSubscriptionCount: Int
}

struct ForgottenRisk: Identifiable {
    let id: UUID
    let name: String
    let amount: Double
    let reasons: [String]
}

struct SavingsScenario: Identifiable {
    let id = UUID()
    let title: String
    let amount: Double
}

struct HealthScoreSummary {
    let score: Int
    let statusKey: String
    let duplicateCount: Int
    let expensiveCount: Int
    let riskCount: Int
    let savingsAmount: Double
}

@Observable
final class AnalyticsViewModel {
    var selectedYear: Int = Calendar.current.component(.year, from: Date())
    var selectedCategoryID: UUID?
    var selectedPeriod: AnalyticsPeriod = .year
    var referenceDate = Date()

    func yearlyForecast(for subscriptions: [Subscription], targetCurrency: String, rates: CurrencyRates) -> Double {
        PaymentCalculator.yearlyForecast(for: filtered(subscriptions), targetCurrency: targetCurrency, rates: rates)
    }

    func periodForecast(for subscriptions: [Subscription], targetCurrency: String, rates: CurrencyRates) -> Double {
        monthlyProjection(for: subscriptions, targetCurrency: targetCurrency, rates: rates)
            .reduce(0) { $0 + $1.amount }
    }

    func averageMonthlyCost(for subscriptions: [Subscription], targetCurrency: String, rates: CurrencyRates) -> Double {
        let period = selectedPeriod.monthCount
        guard period > 0 else { return 0 }
        return periodForecast(for: subscriptions, targetCurrency: targetCurrency, rates: rates) / Double(period)
    }

    func activeCount(for subscriptions: [Subscription]) -> Int {
        filtered(subscriptions).filter(\.isActive).count
    }

    func categorySpending(for subscriptions: [Subscription], targetCurrency: String, rates: CurrencyRates) -> [CategorySpend] {
        let grouped = Dictionary(grouping: periodOccurrences(for: filtered(subscriptions)).filter { $0.subscription.isActive }) {
            $0.subscription.category?.name ?? "Other"
        }

        return grouped.map { name, occurrences in
            let first = occurrences.first?.subscription.category
            return CategorySpend(
                name: name,
                amount: occurrences.reduce(0) { $0 + rates.convert($1.amount, from: $1.currency, to: targetCurrency) },
                colorHex: first?.colorHex ?? "#8E8E93"
            )
        }
        .sorted { $0.amount > $1.amount }
    }

    func annualizedCategorySpending(for subscriptions: [Subscription], targetCurrency: String, rates: CurrencyRates) -> [CategorySpend] {
        let grouped = Dictionary(grouping: filtered(subscriptions).filter(\.isActive)) {
            $0.category?.name ?? "Other"
        }

        return grouped.map { name, items in
            let first = items.first?.category
            return CategorySpend(
                name: name,
                amount: items.reduce(0) { $0 + PaymentCalculator.annualizedAmount(for: $1, targetCurrency: targetCurrency, rates: rates) },
                colorHex: first?.colorHex ?? "#8E8E93"
            )
        }
        .sorted { $0.amount > $1.amount }
    }

    func monthlyProjection(for subscriptions: [Subscription], targetCurrency: String, rates: CurrencyRates) -> [MonthlySpend] {
        projectionMonths().map { date in
            return MonthlySpend(
                month: date,
                amount: PaymentCalculator.monthlyTotal(
                    for: filtered(subscriptions),
                    monthDate: date,
                    targetCurrency: targetCurrency,
                    rates: rates
                )
            )
        }
    }

    private func projectionMonths() -> [Date] {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: referenceDate)
        let currentMonth = calendar.component(.month, from: referenceDate)
        let startMonth = selectedPeriod == .year ? 1 : (selectedYear == currentYear ? currentMonth : 1)

        return (0..<selectedPeriod.monthCount).compactMap { offset in
            calendar.date(from: DateComponents(year: selectedYear, month: startMonth + offset, day: 1))
        }
    }

    private func periodOccurrences(for subscriptions: [Subscription]) -> [PaymentOccurrence] {
        let months = projectionMonths()
        return months.flatMap {
            PaymentCalculator.occurrences(for: subscriptions, inMonthContaining: $0, calendar: Calendar.current)
        }
    }

    func topSubscriptions(for subscriptions: [Subscription], targetCurrency: String, rates: CurrencyRates) -> [SubscriptionSpend] {
        let occurrencesByID = Dictionary(grouping: periodOccurrences(for: filtered(subscriptions)).filter { $0.subscription.isActive }) {
            $0.subscription.id
        }

        return occurrencesByID.compactMap { _, occurrences in
            guard let subscription = occurrences.first?.subscription else { return nil }
            let amount = occurrences.reduce(0) {
                $0 + rates.convert($1.amount, from: $1.currency, to: targetCurrency)
            }
            guard amount > 0 else { return nil }
            return SubscriptionSpend(
                id: subscription.id,
                name: subscription.name,
                iconName: subscription.iconName,
                categoryName: subscription.category?.name ?? "Other",
                colorHex: subscription.category?.colorHex ?? "#8E8E93",
                amount: amount
            )
        }
        .sorted { $0.amount > $1.amount }
    }

    func upcomingWindows(for subscriptions: [Subscription], targetCurrency: String, rates: CurrencyRates) -> [UpcomingSpendWindow] {
        [7, 14, 30].map { days in
            let occurrences = upcomingOccurrences(for: filtered(subscriptions), days: days)
            let amount = occurrences.reduce(0) { total, occurrence in
                total + rates.convert(occurrence.amount, from: occurrence.currency, to: targetCurrency)
            }
            return UpcomingSpendWindow(id: days, days: days, amount: amount, count: occurrences.count)
        }
    }

    func growthSnapshot(for subscriptions: [Subscription], targetCurrency: String, rates: CurrencyRates) -> GrowthSnapshot {
        let calendar = Calendar.current
        let currentMonths = projectionMonths()
        let previousMonths = currentMonths.compactMap {
            calendar.date(byAdding: .month, value: -selectedPeriod.monthCount, to: $0)
        }
        let current = currentMonths.reduce(0) { total, month in
            total + PaymentCalculator.monthlyTotal(
                for: filtered(subscriptions),
                monthDate: month,
                targetCurrency: targetCurrency,
                rates: rates
            )
        }
        let previous = previousMonths.reduce(0) { total, month in
            total + PaymentCalculator.monthlyTotal(
                for: filtered(subscriptions),
                monthDate: month,
                targetCurrency: targetCurrency,
                rates: rates
            )
        }
        let difference = current - previous
        let percent = previous > 0 ? difference / previous : nil
        let periodStart = currentMonths.first ?? Date()
        let newSubscriptions = filtered(subscriptions).filter { $0.isActive && $0.createdAt >= periodStart }
        let newSubscriptionIDs = Set(newSubscriptions.map(\.id))
        let newImpact = periodAmount(
            for: filtered(subscriptions),
            targetCurrency: targetCurrency,
            rates: rates
        ) { newSubscriptionIDs.contains($0.id) }

        return GrowthSnapshot(
            currentPeriod: current,
            previousPeriod: previous,
            difference: difference,
            differencePercent: percent,
            newImpact: newImpact,
            newSubscriptionCount: newSubscriptions.count
        )
    }

    func forgottenRisks(for subscriptions: [Subscription], targetCurrency: String, rates: CurrencyRates) -> [ForgottenRisk] {
        let active = filtered(subscriptions).filter(\.isActive)
        let periodAmountsByID = periodAmountsBySubscriptionID(for: active, targetCurrency: targetCurrency, rates: rates)
        let activeInPeriod = active.filter { (periodAmountsByID[$0.id] ?? 0) > 0 }
        let periodAmounts = Array(periodAmountsByID.values)
        let averagePeriodAmount = periodAmounts.isEmpty ? 0 : periodAmounts.reduce(0, +) / Double(periodAmounts.count)
        let staleDate = Calendar.current.date(byAdding: .day, value: -180, to: referenceDate) ?? referenceDate

        return activeInPeriod.compactMap { subscription in
            let periodAmount = periodAmountsByID[subscription.id] ?? 0
            var reasons: [String] = []
            if subscription.createdAt < staleDate {
                reasons.append("riskOld")
            }
            if periodAmount >= averagePeriodAmount && periodAmount > 0 {
                reasons.append("riskExpensive")
            }
            if subscription.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                reasons.append("riskNoNotes")
            }
            if subscription.billingPeriod == .custom {
                reasons.append("riskManual")
            }

            guard !reasons.isEmpty else { return nil }
            return ForgottenRisk(id: subscription.id, name: subscription.name, amount: periodAmount, reasons: reasons)
        }
        .sorted { $0.amount > $1.amount }
    }

    func savingsScenarios(for subscriptions: [Subscription], targetCurrency: String, rates: CurrencyRates) -> [SavingsScenario] {
        let top = topSubscriptions(for: subscriptions, targetCurrency: targetCurrency, rates: rates)
        var scenarios: [SavingsScenario] = []

        if let first = top.first {
            scenarios.append(SavingsScenario(title: first.name, amount: first.amount))
        }

        if top.count >= 2 {
            let pair = Array(top.prefix(2))
            scenarios.append(
                SavingsScenario(
                    title: pair.map(\.name).joined(separator: " + "),
                    amount: pair.reduce(0) { $0 + $1.amount }
                )
            )
        }

        return scenarios
    }

    func healthScore(for subscriptions: [Subscription], targetCurrency: String, rates: CurrencyRates) -> HealthScoreSummary {
        let active = filtered(subscriptions).filter(\.isActive)
        guard !active.isEmpty else {
            return HealthScoreSummary(
                score: 0,
                statusKey: "healthNoData",
                duplicateCount: 0,
                expensiveCount: 0,
                riskCount: 0,
                savingsAmount: 0
            )
        }

        let top = topSubscriptions(for: active, targetCurrency: targetCurrency, rates: rates)
        let averageAmount = top.isEmpty ? 0 : top.reduce(0) { $0 + $1.amount } / Double(top.count)
        let expensiveCount = top.filter { averageAmount > 0 && $0.amount >= averageAmount * 1.45 }.count
        let duplicateCount = Dictionary(grouping: active) {
            SubscriptionNameNormalizer.normalized($0.name)
        }
        .values
        .filter { $0.count > 1 }
        .reduce(0) { $0 + $1.count }
        let risks = forgottenRisks(for: active, targetCurrency: targetCurrency, rates: rates)
        let savingsAmount = savingsScenarios(for: active, targetCurrency: targetCurrency, rates: rates).last?.amount ?? 0

        // The score is deliberately explainable: each visible risk family lowers
        // the number, while the UI shows the exact contributing counts nearby.
        let penalty = min(60, duplicateCount * 12 + expensiveCount * 8 + risks.count * 6)
        let score = max(0, 100 - penalty)
        let statusKey: String
        if score >= 86 {
            statusKey = "healthExcellent"
        } else if score >= 68 {
            statusKey = "healthGood"
        } else {
            statusKey = "healthNeedsAttention"
        }

        return HealthScoreSummary(
            score: score,
            statusKey: statusKey,
            duplicateCount: duplicateCount,
            expensiveCount: expensiveCount,
            riskCount: risks.count,
            savingsAmount: savingsAmount
        )
    }

    private func filtered(_ subscriptions: [Subscription]) -> [Subscription] {
        guard let selectedCategoryID else { return subscriptions }
        return subscriptions.filter { $0.category?.id == selectedCategoryID }
    }

    private func periodAmountsBySubscriptionID(
        for subscriptions: [Subscription],
        targetCurrency: String,
        rates: CurrencyRates
    ) -> [UUID: Double] {
        Dictionary(grouping: periodOccurrences(for: subscriptions).filter { $0.subscription.isActive }) { $0.subscription.id }
            .mapValues { occurrences in
                occurrences.reduce(0) {
                    $0 + rates.convert($1.amount, from: $1.currency, to: targetCurrency)
                }
            }
    }

    private func periodAmount(
        for subscriptions: [Subscription],
        targetCurrency: String,
        rates: CurrencyRates,
        where predicate: (Subscription) -> Bool
    ) -> Double {
        periodOccurrences(for: subscriptions)
            .filter { predicate($0.subscription) }
            .reduce(0) {
                $0 + rates.convert($1.amount, from: $1.currency, to: targetCurrency)
            }
    }

    private func upcomingOccurrences(for subscriptions: [Subscription], days: Int) -> [PaymentOccurrence] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: referenceDate)
        guard let end = calendar.date(byAdding: .day, value: days, to: start) else { return [] }
        let monthStarts = monthStarts(from: start, through: end, calendar: calendar)

        return monthStarts
            .flatMap { PaymentCalculator.occurrences(for: subscriptions, inMonthContaining: $0, calendar: calendar) }
            .filter { $0.date >= start && $0.date <= end }
            .sorted { $0.date < $1.date }
    }

    private func monthStarts(from start: Date, through end: Date, calendar: Calendar) -> [Date] {
        var months: [Date] = []
        var cursor = calendar.date(from: calendar.dateComponents([.year, .month], from: start)) ?? start

        while cursor <= end {
            months.append(cursor)
            guard let next = calendar.date(byAdding: .month, value: 1, to: cursor) else { break }
            cursor = next
        }

        return months
    }
}
