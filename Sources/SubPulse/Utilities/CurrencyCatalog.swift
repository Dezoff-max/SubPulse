import Foundation

struct CurrencyInfo: Identifiable, Equatable {
    let code: String
    let flag: String
    let country: String
    let centralBankName: String

    var id: String { code }
}

enum CurrencyCatalog {
    static let all: [CurrencyInfo] = [
        CurrencyInfo(code: "USD", flag: "🇺🇸", country: "United States", centralBankName: "Federal Reserve"),
        CurrencyInfo(code: "EUR", flag: "🇪🇺", country: "European Union", centralBankName: "European Central Bank"),
        CurrencyInfo(code: "RUB", flag: "🇷🇺", country: "Russia", centralBankName: "Bank of Russia"),
        CurrencyInfo(code: "GBP", flag: "🇬🇧", country: "United Kingdom", centralBankName: "Bank of England"),
        CurrencyInfo(code: "TRY", flag: "🇹🇷", country: "Turkey", centralBankName: "Central Bank of Turkey")
    ]

    static let supported = all.map(\.code)

    static func info(for code: String) -> CurrencyInfo {
        all.first { $0.code == code.uppercased() } ?? CurrencyInfo(
            code: code.uppercased(),
            flag: "🏳️",
            country: code.uppercased(),
            centralBankName: "Central bank"
        )
    }

    static func localizedCountry(for code: String, language rawLanguage: String) -> String {
        let info = info(for: code)
        let isRussian = (AppLanguage(rawValue: rawLanguage) ?? .system).resolvedCode == "ru"
        guard isRussian else { return info.country }

        return switch info.code {
        case "USD": "США"
        case "EUR": "Евросоюз"
        case "RUB": "Россия"
        case "GBP": "Великобритания"
        case "TRY": "Турция"
        default: info.country
        }
    }

    static func localizedCentralBank(for code: String, language rawLanguage: String) -> String {
        let info = info(for: code)
        let isRussian = (AppLanguage(rawValue: rawLanguage) ?? .system).resolvedCode == "ru"
        guard isRussian else { return info.centralBankName }

        return switch info.code {
        case "USD": "ФРС США"
        case "EUR": "Европейский центральный банк"
        case "RUB": "Банк России"
        case "GBP": "Банк Англии"
        case "TRY": "Центральный банк Турции"
        default: info.centralBankName
        }
    }

    static func cbrRateText(for code: String, rates: CurrencyRates, language rawLanguage: String) -> String {
        let currency = code.uppercased()
        let isRussian = (AppLanguage(rawValue: rawLanguage) ?? .system).resolvedCode == "ru"
        guard let rubRate = rates.ratesToRub[currency] else {
            return isRussian ? "Курс ЦБ РФ недоступен" : "CBR rate unavailable"
        }

        if currency == "RUB" {
            return isRussian ? "Курс ЦБ РФ: 1 RUB = 1 RUB" : "CBR rate: 1 RUB = 1 RUB"
        }

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: isRussian ? "ru_RU" : "en_US")
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 4
        let value = formatter.string(from: NSNumber(value: rubRate)) ?? String(format: "%.2f", rubRate)
        return isRussian ? "Курс ЦБ РФ: 1 \(currency) = \(value) RUB" : "CBR rate: 1 \(currency) = \(value) RUB"
    }
}
