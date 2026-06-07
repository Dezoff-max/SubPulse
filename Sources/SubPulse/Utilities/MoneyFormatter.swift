import Foundation

enum MoneyFormatter {
    static func string(_ value: Double, currency: String = "USD", compact: Bool = false, rounded: Bool = false) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = compact ? .currencyISOCode : .currency
        formatter.currencyCode = currency
        if !compact {
            formatter.currencySymbol = symbol(for: currency)
        }
        formatter.maximumFractionDigits = rounded || value.rounded() == value ? 0 : 2
        return formatter.string(from: NSNumber(value: value)) ?? "\(currency) \(value)"
    }

    private static func symbol(for currency: String) -> String {
        switch currency.uppercased() {
        case "RUB": "₽"
        case "TRY": "₺"
        case "EUR": "€"
        case "GBP": "£"
        case "USD": "$"
        default: currency
        }
    }
}
