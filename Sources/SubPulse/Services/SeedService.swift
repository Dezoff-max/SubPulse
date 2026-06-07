import Foundation
import SwiftData

enum SeedService {
    private static let demoSeedCompletedKey = "seed.demoSubscriptions.completed"
    private static let allDataResetKey = "seed.allDataReset.completed"

    static func markDemoSeedCompleted() {
        UserDefaults.standard.set(true, forKey: demoSeedCompletedKey)
    }

    static func markAllDataResetCompleted() {
        UserDefaults.standard.set(true, forKey: allDataResetKey)
        markDemoSeedCompleted()
    }

    static func clearDemoSeedMarkerForTests() {
        UserDefaults.standard.removeObject(forKey: demoSeedCompletedKey)
        UserDefaults.standard.removeObject(forKey: allDataResetKey)
    }

    static func seedIfNeeded(in context: ModelContext) {
        let descriptor = FetchDescriptor<Subscription>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        migrateLegacyIcons(in: context)
        guard !UserDefaults.standard.bool(forKey: allDataResetKey) else { return }

        seedMissingPopularCategories(in: context)
        normalizePaymentMethods(in: context)
        if count > 0 {
            markDemoSeedCompleted()
            return
        }

        guard !UserDefaults.standard.bool(forKey: demoSeedCompletedKey) else { return }

        let categories = categoriesByName(in: context)
        let storage = categories["Cloud Storage"] ?? categories["Storage"] ?? Category(name: "Cloud Storage", colorHex: "#4F8EF7", iconName: "☁️")
        let ai = categories["AI Tools"] ?? Category(name: "AI Tools", colorHex: "#AF52DE", iconName: "✨")

        let paymentMethods = paymentMethodsByName(in: context)
        let applePay = paymentMethods["Apple Pay"] ?? PaymentMethod(name: "Apple Pay", type: "Wallet", last4: nil, colorHex: "#8E8E93")
        let debitCard = paymentMethods["Дебетовая карта"] ?? PaymentMethod(name: "Дебетовая карта", type: "Debit", last4: nil, colorHex: "#007AFF")

        if paymentMethods["Apple Pay"] == nil { context.insert(applePay) }
        if paymentMethods["Дебетовая карта"] == nil { context.insert(debitCard) }

        let calendar = Calendar.current
        let now = Date()
        let iCloudDate = calendar.date(byAdding: .day, value: 3, to: now) ?? now
        let googleDate = calendar.date(byAdding: .day, value: 9, to: now) ?? now
        let chatGPTDate = calendar.date(byAdding: .day, value: 15, to: now) ?? now

        let subscriptions = [
            Subscription(
                name: "iCloud+",
                amount: 2.99,
                billingPeriod: .monthly,
                nextPaymentDate: iCloudDate,
                category: storage,
                paymentMethod: applePay,
                iconName: "☁️"
            ),
            Subscription(
                name: "Google One",
                amount: 1.99,
                billingPeriod: .monthly,
                nextPaymentDate: googleDate,
                category: storage,
                paymentMethod: debitCard,
                iconName: "📦"
            ),
            Subscription(
                name: "ChatGPT",
                amount: 20,
                billingPeriod: .monthly,
                nextPaymentDate: chatGPTDate,
                category: ai,
                paymentMethod: debitCard,
                iconName: "✨"
            )
        ]

        subscriptions.forEach(context.insert)
        try? context.save()
        markDemoSeedCompleted()
    }

    private static func migrateLegacyIcons(in context: ModelContext) {
        let subscriptions = (try? context.fetch(FetchDescriptor<Subscription>())) ?? []
        let categories = (try? context.fetch(FetchDescriptor<Category>())) ?? []

        var changed = false
        for subscription in subscriptions {
            let migrated = EmojiIcon.migrateLegacyValue(subscription.iconName)
            if migrated != subscription.iconName {
                subscription.iconName = migrated
                changed = true
            }
        }

        for category in categories {
            let migrated = EmojiIcon.migrateLegacyValue(category.iconName)
            if migrated != category.iconName {
                category.iconName = migrated
                changed = true
            }
        }

        if changed {
            try? context.save()
        }
    }

    private static func seedMissingPopularCategories(in context: ModelContext) {
        let existing = Set(((try? context.fetch(FetchDescriptor<Category>())) ?? []).map(\.name))
        let popular = [
            CategorySeed(name: "Streaming", colorHex: "#FF2D55", iconName: "🎬"),
            CategorySeed(name: "Music", colorHex: "#1DB954", iconName: "🎵"),
            CategorySeed(name: "Cloud Storage", colorHex: "#4F8EF7", iconName: "☁️"),
            CategorySeed(name: "AI Tools", colorHex: "#AF52DE", iconName: "✨"),
            CategorySeed(name: "Productivity", colorHex: "#34C759", iconName: "✅"),
            CategorySeed(name: "Software", colorHex: "#5856D6", iconName: "🧩"),
            CategorySeed(name: "Gaming", colorHex: "#FF9500", iconName: "🎮"),
            CategorySeed(name: "News & Media", colorHex: "#FF3B30", iconName: "📰"),
            CategorySeed(name: "Fitness", colorHex: "#30D158", iconName: "🏋️"),
            CategorySeed(name: "Finance", colorHex: "#00C7BE", iconName: "💳"),
            CategorySeed(name: "Education", colorHex: "#64D2FF", iconName: "📚"),
            CategorySeed(name: "Security", colorHex: "#8E8E93", iconName: "🛡️"),
            CategorySeed(name: "Utilities", colorHex: "#BF5AF2", iconName: "🧰"),
            CategorySeed(name: "Family", colorHex: "#FF9F0A", iconName: "👨‍👩‍👧")
        ]

        var inserted = false
        for item in popular where !existing.contains(item.name) {
            context.insert(Category(name: item.name, colorHex: item.colorHex, iconName: item.iconName))
            inserted = true
        }

        if inserted {
            try? context.save()
        }
    }

    private static func normalizePaymentMethods(in context: ModelContext) {
        let methods = (try? context.fetch(FetchDescriptor<PaymentMethod>())) ?? []
        let existingByName = Dictionary(grouping: methods, by: \.name)
        let allowed = paymentMethodSeeds.map(\.name)

        for seed in paymentMethodSeeds where existingByName[seed.name]?.isEmpty != false {
            context.insert(PaymentMethod(name: seed.name, type: seed.type, last4: nil, colorHex: seed.colorHex))
        }

        let refreshed = (try? context.fetch(FetchDescriptor<PaymentMethod>())) ?? []
        for method in refreshed {
            guard let seed = paymentMethodSeeds.first(where: { $0.name == method.name }) else { continue }
            method.type = seed.type
            method.last4 = nil
            method.colorHex = seed.colorHex
        }

        let applePay = refreshed.first { $0.name == "Apple Pay" }
        let debitCard = refreshed.first { $0.name == "Дебетовая карта" }

        let subscriptions = (try? context.fetch(FetchDescriptor<Subscription>())) ?? []
        // Older demo databases may contain generic Wallet/Credit records. Keep
        // user-created methods intact, and only retarget obvious legacy names.
        for subscription in subscriptions {
            guard let method = subscription.paymentMethod, !allowed.contains(method.name) else { continue }
            let legacyName = method.name.lowercased()
            guard ["visa", "wallet", "card"].contains(legacyName) else { continue }
            if legacyName.contains("apple") {
                subscription.paymentMethod = applePay
            } else if legacyName.contains("credit") {
                subscription.paymentMethod = refreshed.first { $0.name == "Кредитная карта" } ?? debitCard
            } else if legacyName.contains("google") {
                subscription.paymentMethod = refreshed.first { $0.name == "Google Pay" } ?? debitCard
            } else {
                subscription.paymentMethod = debitCard
            }
        }

        try? context.save()
    }

    private static func categoriesByName(in context: ModelContext) -> [String: Category] {
        let categories = (try? context.fetch(FetchDescriptor<Category>())) ?? []
        var result: [String: Category] = [:]
        for category in categories where result[category.name] == nil {
            result[category.name] = category
        }
        return result
    }

    private static func paymentMethodsByName(in context: ModelContext) -> [String: PaymentMethod] {
        let methods = (try? context.fetch(FetchDescriptor<PaymentMethod>())) ?? []
        var result: [String: PaymentMethod] = [:]
        for method in methods where result[method.name] == nil {
            result[method.name] = method
        }
        return result
    }
}

private struct CategorySeed {
    let name: String
    let colorHex: String
    let iconName: String
}

private let paymentMethodSeeds = [
    PaymentMethodSeed(name: "Apple Pay", type: "Wallet", colorHex: "#8E8E93"),
    PaymentMethodSeed(name: "Google Pay", type: "Wallet", colorHex: "#34A853"),
    PaymentMethodSeed(name: "Дебетовая карта", type: "Debit", colorHex: "#007AFF"),
    PaymentMethodSeed(name: "Кредитная карта", type: "Credit", colorHex: "#AF52DE")
]

private struct PaymentMethodSeed {
    let name: String
    let type: String
    let colorHex: String
}
