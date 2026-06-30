import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

enum WidgetSnapshotService {
    static let widgetKind = "SubPulseRenewalsWidget"
    static let widgetBundleIdentifier = "com.subpulse.app.widgets"

    static var snapshotURL: URL {
        appSupportSnapshotURL
    }

    private static var applicationSupportDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent("SubPulse", isDirectory: true)
    }

    static func write(
        subscriptions: [Subscription],
        baseCurrency: String,
        language: String,
        rates: CurrencyRates,
        compactNumbers: Bool,
        roundingEnabled: Bool,
        referenceDate: Date = Date()
    ) {
        do {
            try FileManager.default.createDirectory(
                at: applicationSupportDirectory,
                withIntermediateDirectories: true
            )

            let snapshot = makeSnapshot(
                subscriptions: subscriptions,
                baseCurrency: baseCurrency,
                language: language,
                rates: rates,
                compactNumbers: compactNumbers,
                roundingEnabled: roundingEnabled,
                referenceDate: referenceDate
            )
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(snapshot)
            for url in snapshotURLs {
                try FileManager.default.createDirectory(
                    at: url.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                try data.write(to: url, options: .atomic)
            }

            #if canImport(WidgetKit)
            WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
            #endif
        } catch {
            #if DEBUG
            print("Widget snapshot write failed: \(error)")
            #endif
        }
    }

    private static var snapshotURLs: [URL] {
        var urls = [appSupportSnapshotURL]
        if let widgetContainerSnapshotURL {
            urls.append(widgetContainerSnapshotURL)
        }
        var seen = Set<URL>()
        return urls.filter { seen.insert($0).inserted }
    }

    private static var appSupportSnapshotURL: URL {
        applicationSupportDirectory.appendingPathComponent("WidgetSnapshot.json")
    }

    private static var widgetContainerSnapshotURL: URL? {
        let base = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Containers", isDirectory: true)
            .appendingPathComponent(widgetBundleIdentifier, isDirectory: true)
            .appendingPathComponent("Data", isDirectory: true)
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Application Support", isDirectory: true)

        return base
            .appendingPathComponent("SubPulse", isDirectory: true)
            .appendingPathComponent("WidgetSnapshot.json")
    }

    private static func makeSnapshot(
        subscriptions: [Subscription],
        baseCurrency: String,
        language: String,
        rates: CurrencyRates,
        compactNumbers: Bool,
        roundingEnabled: Bool,
        referenceDate: Date
    ) -> SubPulseWidgetSnapshot {
        let calendar = L10n.calendar(language: language)
        let monthOccurrences = PaymentCalculator.occurrences(
            for: subscriptions,
            inMonthContaining: referenceDate,
            calendar: calendar
        )
        let monthTotal = monthOccurrences.reduce(0) { total, occurrence in
            total + rates.convert(occurrence.amount, from: occurrence.currency, to: baseCurrency)
        }

        let today = calendar.startOfDay(for: referenceDate)
        let upcoming = upcomingOccurrences(
            for: subscriptions,
            from: today,
            calendar: calendar
        )

        let nextPayment = upcoming.first.map {
            makePayment(
                occurrence: $0,
                today: today,
                baseCurrency: baseCurrency,
                language: language,
                rates: rates,
                compactNumbers: compactNumbers,
                roundingEnabled: roundingEnabled,
                calendar: calendar
            )
        }

        let calendarSnapshot = makeCalendar(
            monthDate: referenceDate,
            occurrences: monthOccurrences,
            today: today,
            baseCurrency: baseCurrency,
            language: language,
            rates: rates,
            compactNumbers: compactNumbers,
            roundingEnabled: roundingEnabled,
            calendar: calendar
        )

        return SubPulseWidgetSnapshot(
            generatedAt: Date(),
            languageCode: (AppLanguage(rawValue: language) ?? .system).resolvedCode,
            baseCurrency: baseCurrency,
            monthTitle: L10n.monthYear(referenceDate, language: language),
            monthTotal: MoneyFormatter.string(
                monthTotal,
                currency: baseCurrency,
                compact: compactNumbers,
                rounded: roundingEnabled
            ),
            renewalCount: monthOccurrences.count,
            renewalCountText: String(
                format: L10n.text("renewalsThisMonthFormat", language: language),
                monthOccurrences.count
            ),
            nextText: nextRenewalText(for: upcoming.first, today: today, language: language, calendar: calendar),
            nextPayment: nextPayment,
            upcoming: upcoming.prefix(6).map {
                makePayment(
                    occurrence: $0,
                    today: today,
                    baseCurrency: baseCurrency,
                    language: language,
                    rates: rates,
                    compactNumbers: compactNumbers,
                    roundingEnabled: roundingEnabled,
                    calendar: calendar
                )
            },
            calendar: calendarSnapshot
        )
    }

    private static func upcomingOccurrences(
        for subscriptions: [Subscription],
        from today: Date,
        calendar: Calendar
    ) -> [PaymentOccurrence] {
        (0..<6)
            .compactMap { calendar.date(byAdding: .month, value: $0, to: today) }
            .flatMap { month in
                PaymentCalculator.occurrences(
                    for: subscriptions,
                    inMonthContaining: month,
                    calendar: calendar
                )
            }
            .filter { calendar.startOfDay(for: $0.date) >= today }
            .sorted { lhs, rhs in
                if lhs.date == rhs.date {
                    return lhs.subscription.name.localizedCaseInsensitiveCompare(rhs.subscription.name) == .orderedAscending
                }
                return lhs.date < rhs.date
            }
    }

    private static func makeCalendar(
        monthDate: Date,
        occurrences: [PaymentOccurrence],
        today: Date,
        baseCurrency: String,
        language: String,
        rates: CurrencyRates,
        compactNumbers: Bool,
        roundingEnabled: Bool,
        calendar: Calendar
    ) -> SubPulseWidgetCalendar {
        let days = DateUtilities.daysInMonth(containing: monthDate, calendar: calendar)
        let leadingBlanks = DateUtilities.leadingEmptyDays(for: monthDate, calendar: calendar)
        var cells: [SubPulseWidgetDay] = (0..<leadingBlanks).map { index in
            SubPulseWidgetDay(
                id: "blank-\(index)",
                day: nil,
                isToday: false,
                amount: nil,
                payments: []
            )
        }

        for day in days {
            let dayPayments = occurrences.filter { calendar.isDate($0.date, inSameDayAs: day) }
            let dayTotal = dayPayments.reduce(0) { total, occurrence in
                total + rates.convert(occurrence.amount, from: occurrence.currency, to: baseCurrency)
            }
            let amount = dayTotal > 0
                ? MoneyFormatter.string(dayTotal, currency: baseCurrency, compact: compactNumbers, rounded: roundingEnabled)
                : nil

            cells.append(
                SubPulseWidgetDay(
                    id: ISO8601DateFormatter().string(from: day),
                    day: calendar.component(.day, from: day),
                    isToday: calendar.isDate(day, inSameDayAs: today),
                    amount: amount,
                    payments: dayPayments.prefix(2).map {
                        makePayment(
                            occurrence: $0,
                            today: today,
                            baseCurrency: baseCurrency,
                            language: language,
                            rates: rates,
                            compactNumbers: compactNumbers,
                            roundingEnabled: roundingEnabled,
                            calendar: calendar
                        )
                    }
                )
            )
        }

        return SubPulseWidgetCalendar(
            weekdaySymbols: L10n.shortWeekdaySymbols(language: language),
            cells: cells
        )
    }

    private static func makePayment(
        occurrence: PaymentOccurrence,
        today: Date,
        baseCurrency: String,
        language: String,
        rates: CurrencyRates,
        compactNumbers: Bool,
        roundingEnabled: Bool,
        calendar: Calendar
    ) -> SubPulseWidgetPayment {
        let convertedAmount = rates.convert(occurrence.amount, from: occurrence.currency, to: baseCurrency)
        let paymentDay = calendar.startOfDay(for: occurrence.date)
        let daysUntil = calendar.dateComponents([.day], from: today, to: paymentDay).day ?? 0

        return SubPulseWidgetPayment(
            id: "\(occurrence.subscription.id.uuidString)-\(Int(occurrence.date.timeIntervalSince1970))",
            name: occurrence.subscription.name,
            amount: MoneyFormatter.string(
                convertedAmount,
                currency: baseCurrency,
                compact: compactNumbers,
                rounded: roundingEnabled
            ),
            date: L10n.shortDate(occurrence.date, language: language),
            dayNumber: calendar.component(.day, from: occurrence.date),
            relativeDate: relativeDateText(daysUntil: daysUntil, language: language),
            brand: brandStyle(
                name: occurrence.subscription.name,
                fallbackIcon: occurrence.subscription.iconName,
                fallbackColor: occurrence.subscription.category?.colorHex ?? "#007AFF"
            )
        )
    }

    private static func nextRenewalText(
        for occurrence: PaymentOccurrence?,
        today: Date,
        language: String,
        calendar: Calendar
    ) -> String {
        guard let occurrence else {
            return L10n.text("noPayments", language: language)
        }

        let paymentDay = calendar.startOfDay(for: occurrence.date)
        let days = calendar.dateComponents([.day], from: today, to: paymentDay).day ?? 0
        if days <= 0 {
            return L10n.text("dueToday", language: language)
        }
        return String(format: L10n.text("nextRenewalInDays", language: language), days)
    }

    private static func relativeDateText(daysUntil: Int, language: String) -> String {
        let isRussian = (AppLanguage(rawValue: language) ?? .system).resolvedCode == "ru"
        if daysUntil <= 0 {
            return isRussian ? "Сегодня" : "Today"
        }
        if daysUntil == 1 {
            return isRussian ? "Завтра" : "Tomorrow"
        }
        return isRussian ? "Через \(daysUntil) дн." : "In \(daysUntil)d"
    }

    private static func brandStyle(name: String, fallbackIcon: String, fallbackColor: String) -> SubPulseWidgetBrand {
        let normalized = name.lowercased()

        if normalized.contains("netflix") {
            return SubPulseWidgetBrand(mark: "N", backgroundHex: "#E6050A", foregroundHex: "#FFFFFF", usesOpenAIGlyph: false)
        }
        if normalized.contains("spotify") {
            return SubPulseWidgetBrand(mark: "♫", backgroundHex: "#1DB954", foregroundHex: "#111111", usesOpenAIGlyph: false)
        }
        if normalized.contains("youtube") {
            return SubPulseWidgetBrand(mark: "▶", backgroundHex: "#FF0000", foregroundHex: "#FFFFFF", usesOpenAIGlyph: false)
        }
        if normalized.contains("icloud") {
            return SubPulseWidgetBrand(mark: "☁", backgroundHex: "#2E7AFF", foregroundHex: "#FFFFFF", usesOpenAIGlyph: false)
        }
        if normalized.contains("google") {
            return SubPulseWidgetBrand(mark: "G", backgroundHex: "#FFFFFF", foregroundHex: "#2D6CDF", usesOpenAIGlyph: false)
        }
        if normalized.contains("chatgpt") || normalized.contains("openai") {
            return SubPulseWidgetBrand(mark: "", backgroundHex: "#FFFFFF", foregroundHex: "#111111", usesOpenAIGlyph: true)
        }

        return SubPulseWidgetBrand(
            mark: EmojiIcon.emoji(for: fallbackIcon),
            backgroundHex: fallbackColor,
            foregroundHex: "#FFFFFF",
            usesOpenAIGlyph: false
        )
    }
}

struct SubPulseWidgetSnapshot: Codable {
    let generatedAt: Date
    let languageCode: String
    let baseCurrency: String
    let monthTitle: String
    let monthTotal: String
    let renewalCount: Int
    let renewalCountText: String
    let nextText: String
    let nextPayment: SubPulseWidgetPayment?
    let upcoming: [SubPulseWidgetPayment]
    let calendar: SubPulseWidgetCalendar
}

struct SubPulseWidgetCalendar: Codable {
    let weekdaySymbols: [String]
    let cells: [SubPulseWidgetDay]
}

struct SubPulseWidgetDay: Codable {
    let id: String
    let day: Int?
    let isToday: Bool
    let amount: String?
    let payments: [SubPulseWidgetPayment]
}

struct SubPulseWidgetPayment: Codable {
    let id: String
    let name: String
    let amount: String
    let date: String
    let dayNumber: Int
    let relativeDate: String
    let brand: SubPulseWidgetBrand
}

struct SubPulseWidgetBrand: Codable {
    let mark: String
    let backgroundHex: String
    let foregroundHex: String
    let usesOpenAIGlyph: Bool
}
