import Foundation

enum BillingPeriod: String, CaseIterable, Codable, Identifiable {
    case weekly
    case monthly
    case yearly
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .weekly: "Weekly"
        case .monthly: "Monthly"
        case .yearly: "Yearly"
        case .custom: "Custom"
        }
    }

    func localizedTitle(language: String) -> String {
        switch self {
        case .weekly: L10n.text("weekly", language: language)
        case .monthly: L10n.text("monthly", language: language)
        case .yearly: L10n.text("yearly", language: language)
        case .custom: L10n.text("custom", language: language)
        }
    }

    var symbolName: String {
        switch self {
        case .weekly: "calendar.badge.clock"
        case .monthly: "calendar"
        case .yearly: "calendar.circle"
        case .custom: "slider.horizontal.3"
        }
    }

    var emoji: String {
        switch self {
        case .weekly: "🔁"
        case .monthly: "📅"
        case .yearly: "🗓️"
        case .custom: "🎛️"
        }
    }
}
