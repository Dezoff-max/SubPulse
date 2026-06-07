import Foundation
import Observation

enum SubscriptionFilter: String, CaseIterable, Identifiable {
    case active
    case archived
    case all

    var id: String { rawValue }
    var title: String { rawValue.capitalized }

    func localizedTitle(language: String) -> String {
        switch self {
        case .active: L10n.text("activeFilter", language: language)
        case .archived: L10n.text("archivedFilter", language: language)
        case .all: L10n.text("allFilter", language: language)
        }
    }
}

enum SubscriptionSort: String, CaseIterable, Identifiable {
    case date
    case amount
    case name

    var id: String { rawValue }
    var title: String { rawValue.capitalized }

    func localizedTitle(language: String) -> String {
        switch self {
        case .date: L10n.text("dateSort", language: language)
        case .amount: L10n.text("amountSort", language: language)
        case .name: L10n.text("nameSort", language: language)
        }
    }
}

@Observable
final class SubscriptionListViewModel {
    var filter: SubscriptionFilter = .active
    var sort: SubscriptionSort = .date
    var searchText: String = ""

    func visibleSubscriptions(from subscriptions: [Subscription]) -> [Subscription] {
        let filtered = subscriptions.filter { subscription in
            let matchesFilter: Bool
            switch filter {
            case .active: matchesFilter = subscription.isActive
            case .archived: matchesFilter = !subscription.isActive
            case .all: matchesFilter = true
            }

            let matchesSearch = searchText.isEmpty ||
                subscription.name.localizedCaseInsensitiveContains(searchText) ||
                (subscription.category?.name.localizedCaseInsensitiveContains(searchText) ?? false)

            return matchesFilter && matchesSearch
        }

        return filtered.sorted { lhs, rhs in
            switch sort {
            case .date: lhs.billableNextPaymentDate() < rhs.billableNextPaymentDate()
            case .amount: lhs.amount > rhs.amount
            case .name: lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
        }
    }
}
