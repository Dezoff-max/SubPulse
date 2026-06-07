import Foundation

enum AppStoreImportParser {
    static func parse(_ text: String) -> [AppStoreImportResult] {
        let lines = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var results: [AppStoreImportResult] = []
        var seen = Set<String>()

        for index in lines.indices {
            guard let price = price(in: lines[index]) else { continue }

            let name = nameInPriceLine(lines[index], priceRange: price.range) ??
                nearestName(before: index, in: lines) ??
                nearestName(after: index, in: lines)

            guard let name, !name.isEmpty else { continue }

            let window = contextWindow(around: index, in: lines)
            let period = billingPeriod(in: window)
            let nextDate = nextPaymentDate(in: window)
            let key = "\(name.normalizedImportToken)|\(price.amount)|\(price.currency)"

            guard !seen.contains(key) else { continue }
            seen.insert(key)

            results.append(
                AppStoreImportResult(
                    name: cleanupName(name),
                    amount: price.amount,
                    currency: price.currency,
                    billingPeriod: period,
                    nextPaymentDate: nextDate,
                    sourceText: window.joined(separator: "\n")
                )
            )
        }

        return results
    }

    private struct ParsedPrice {
        let amount: Double
        let currency: String
        let range: NSRange
    }

    private static func price(in line: String) -> ParsedPrice? {
        let patterns = [
            #"([$€£₺₽])\s*([0-9][0-9\s.,]*)"#,
            #"([0-9][0-9\s.,]*)\s*([$€£₺₽])"#,
            #"([0-9][0-9\s.,]*)\s*(USD|RUB|TRY|EUR|GBP|TL)"#
        ]

        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { continue }
            let nsRange = NSRange(line.startIndex..<line.endIndex, in: line)
            guard let match = regex.firstMatch(in: line, range: nsRange), match.numberOfRanges >= 3 else { continue }

            let first = substring(line, match.range(at: 1))
            let second = substring(line, match.range(at: 2))
            let amountText = first.containsDigit ? first : second
            let currencyText = first.containsDigit ? second : first

            guard let amount = parseAmount(amountText), amount > 0 else { continue }

            return ParsedPrice(
                amount: amount,
                currency: currency(from: currencyText),
                range: match.range
            )
        }

        return nil
    }

    private static func nameInPriceLine(_ line: String, priceRange: NSRange) -> String? {
        guard let range = Range(priceRange, in: line) else { return nil }
        let removed = line.replacingCharacters(in: range, with: " ")
        let cleaned = cleanupName(removed)
        return isLikelyName(cleaned) ? cleaned : nil
    }

    private static func nearestName(before index: Int, in lines: [String]) -> String? {
        guard index > 0 else { return nil }
        for candidateIndex in stride(from: index - 1, through: max(0, index - 4), by: -1) {
            let candidate = cleanupName(lines[candidateIndex])
            if isLikelyName(candidate) {
                return candidate
            }
        }
        return nil
    }

    private static func nearestName(after index: Int, in lines: [String]) -> String? {
        guard index < lines.count - 1 else { return nil }
        for candidateIndex in min(lines.count - 1, index + 1)...min(lines.count - 1, index + 3) {
            let candidate = cleanupName(lines[candidateIndex])
            if isLikelyName(candidate) {
                return candidate
            }
        }
        return nil
    }

    private static func contextWindow(around index: Int, in lines: [String]) -> [String] {
        let start = max(0, index - 3)
        let end = min(lines.count - 1, index + 3)
        return Array(lines[start...end])
    }

    private static func billingPeriod(in lines: [String]) -> BillingPeriod {
        let joined = lines.joined(separator: " ").lowercased()

        if joined.contains("year") || joined.contains("annual") || joined.contains("год") {
            return .yearly
        }
        if joined.contains("week") || joined.contains("недел") {
            return .weekly
        }
        return .monthly
    }

    private static func nextPaymentDate(in lines: [String]) -> Date? {
        let joined = lines.joined(separator: " ")
        let datePatterns = [
            #"([0-9]{2}\.[0-9]{2}\.[0-9]{4})"#,
            #"([0-9]{4}-[0-9]{2}-[0-9]{2})"#,
            #"([0-9]{1,2}/[0-9]{1,2}/[0-9]{4})"#
        ]

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current

        for pattern in datePatterns {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            let nsRange = NSRange(joined.startIndex..<joined.endIndex, in: joined)
            guard let match = regex.firstMatch(in: joined, range: nsRange) else { continue }
            let value = substring(joined, match.range(at: 1))

            for format in ["dd.MM.yyyy", "yyyy-MM-dd", "M/d/yyyy", "MM/dd/yyyy"] {
                formatter.dateFormat = format
                if let date = formatter.date(from: value) {
                    return Calendar.current.startOfDay(for: date)
                }
            }
        }

        return nil
    }

    private static func isLikelyName(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2, trimmed.count <= 42 else { return false }
        guard !priceLike(trimmed) else { return false }

        let lower = trimmed.lowercased()
        let banned = [
            "app store", "subscriptions", "subscription", "подписки", "подписка",
            "active", "expired", "expires", "renews", "renewal", "billing",
            "активно", "истекает", "продлевается", "оплата", "списание",
            "month", "monthly", "year", "yearly", "week", "weekly",
            "месяц", "год", "неделя", "ежемесячно", "ежегодно", "еженедельно",
            "total", "price", "сумма", "цена", "next", "следующий"
        ]

        return !banned.contains { lower.contains($0) }
    }

    private static func priceLike(_ value: String) -> Bool {
        price(in: value) != nil
    }

    private static func parseAmount(_ value: String) -> Double? {
        let normalized = value
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "\u{00a0}", with: "")
            .replacingOccurrences(of: ",", with: ".")
            .filter { $0.isNumber || $0 == "." }

        return Double(normalized)
    }

    private static func currency(from value: String) -> String {
        switch value.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() {
        case "$", "USD":
            return "USD"
        case "₽", "RUB":
            return "RUB"
        case "₺", "TRY", "TL":
            return "TRY"
        case "€", "EUR":
            return "EUR"
        case "£", "GBP":
            return "GBP"
        default:
            return "USD"
        }
    }

    private static func cleanupName(_ value: String) -> String {
        value
            .replacingOccurrences(of: "•", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters))
    }

    private static func substring(_ value: String, _ range: NSRange) -> String {
        guard let swiftRange = Range(range, in: value) else { return "" }
        return String(value[swiftRange])
    }
}

private extension String {
    var containsDigit: Bool {
        contains { $0.isNumber }
    }

    var normalizedImportToken: String {
        lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "+", with: "")
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: "-", with: "")
    }
}
