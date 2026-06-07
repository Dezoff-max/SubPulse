import Foundation

enum AppDestination: String, CaseIterable, Identifiable {
    case dashboard
    case calendar
    case subscriptions
    case analytics
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard: "All Subs"
        case .calendar: "Calendar"
        case .subscriptions: "Subscriptions"
        case .analytics: "Analytics"
        case .settings: "Settings"
        }
    }

    func localizedTitle(language: String) -> String {
        switch self {
        case .dashboard: L10n.text("dashboard", language: language)
        case .calendar: L10n.text("calendar", language: language)
        case .subscriptions: L10n.text("subscriptions", language: language)
        case .analytics: L10n.text("analytics", language: language)
        case .settings: L10n.text("settings", language: language)
        }
    }

    var symbolName: String {
        switch self {
        case .dashboard: "square.grid.2x2"
        case .calendar: "calendar"
        case .subscriptions: "list.bullet.rectangle"
        case .analytics: "chart.pie"
        case .settings: "gearshape"
        }
    }

    var emoji: String {
        switch self {
        case .dashboard: "🔷"
        case .calendar: "📅"
        case .subscriptions: "📋"
        case .analytics: "📊"
        case .settings: "⚙️"
        }
    }
}
