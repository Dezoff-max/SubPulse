import Foundation

struct SubscriptionPreset: Identifiable {
    let id = UUID()
    let name: String
    let amount: Double
    let categoryName: String
    let iconName: String
    let isPopular: Bool

    func draft(categories: [Category], paymentMethods: [PaymentMethod]) -> SubscriptionDraft {
        var draft = SubscriptionDraft()
        draft.name = name
        draft.amount = amount
        draft.billingPeriod = .monthly
        draft.nextPaymentDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
        draft.category = categories.first { $0.name == categoryName }
        draft.paymentMethod = paymentMethods.first
        draft.iconName = iconName
        return draft
    }
}

enum SubscriptionPresetCatalog {
    static let all: [SubscriptionPreset] = [
        SubscriptionPreset(name: "YouTube", amount: 8.99, categoryName: "Streaming", iconName: "▶", isPopular: true),
        SubscriptionPreset(name: "Spotify", amount: 12.99, categoryName: "Music", iconName: "♫", isPopular: true),
        SubscriptionPreset(name: "Netflix", amount: 8.99, categoryName: "Streaming", iconName: "N", isPopular: true),
        SubscriptionPreset(name: "LinkedIn", amount: 29.99, categoryName: "Productivity", iconName: "in", isPopular: true),
        SubscriptionPreset(name: "Cursor", amount: 20, categoryName: "AI Tools", iconName: "⌁", isPopular: true),
        SubscriptionPreset(name: "Claude", amount: 20, categoryName: "AI Tools", iconName: "✺", isPopular: true),
        SubscriptionPreset(name: "ChatGPT", amount: 20, categoryName: "AI Tools", iconName: "AI", isPopular: true),
        SubscriptionPreset(name: "Apple One", amount: 19.95, categoryName: "Family", iconName: "", isPopular: true),
        SubscriptionPreset(name: "Apple Music", amount: 10.99, categoryName: "Music", iconName: "♪", isPopular: true),
        SubscriptionPreset(name: "Apple iCloud", amount: 0.99, categoryName: "Cloud Storage", iconName: "☁", isPopular: true),
        SubscriptionPreset(name: "Amazon Prime Video", amount: 8.99, categoryName: "Streaming", iconName: "p", isPopular: true),
        SubscriptionPreset(name: "1Password", amount: 3.99, categoryName: "Security", iconName: "1", isPopular: true),
        SubscriptionPreset(name: "Adobe Cloud", amount: 54.99, categoryName: "Software", iconName: "A", isPopular: false),
        SubscriptionPreset(name: "Amazon Music", amount: 11.99, categoryName: "Music", iconName: "♫", isPopular: false),
        SubscriptionPreset(name: "Apple Arcade", amount: 6.99, categoryName: "Gaming", iconName: "🎮", isPopular: false),
        SubscriptionPreset(name: "Apple Care+", amount: 3.99, categoryName: "Utilities", iconName: "🛡️", isPopular: false),
        SubscriptionPreset(name: "Apple Developer", amount: 8.25, categoryName: "Software", iconName: "", isPopular: false),
        SubscriptionPreset(name: "Apple Fitness+", amount: 9.99, categoryName: "Fitness", iconName: "🏋️", isPopular: false),
        SubscriptionPreset(name: "Apple TV", amount: 12.99, categoryName: "Streaming", iconName: "tv", isPopular: false),
        SubscriptionPreset(name: "Audible", amount: 7.95, categoryName: "Education", iconName: "A", isPopular: false),
        SubscriptionPreset(name: "Calm", amount: 14.99, categoryName: "Fitness", iconName: "☾", isPopular: false),
        SubscriptionPreset(name: "Canva", amount: 15, categoryName: "Productivity", iconName: "C", isPopular: false),
        SubscriptionPreset(name: "Discord Nitro", amount: 2.99, categoryName: "Gaming", iconName: "D", isPopular: false),
        SubscriptionPreset(name: "Figma", amount: 15, categoryName: "Software", iconName: "F", isPopular: false),
        SubscriptionPreset(name: "Notion", amount: 12, categoryName: "Productivity", iconName: "N", isPopular: false),
        SubscriptionPreset(name: "Telegram Premium", amount: 4.99, categoryName: "Utilities", iconName: "✈", isPopular: false)
    ]
}
