import SwiftData
import XCTest
@testable import SubPulse

@MainActor
final class BackupSnapshotTests: XCTestCase {
    func testBackupDataEncodesSchemaAndSubscriptions() throws {
        let category = Category(name: "Productivity", colorHex: "#34C759", iconName: "checkmark")
        let method = PaymentMethod(name: "Apple Pay", type: "wallet", colorHex: "#007AFF")
        let subscription = Subscription(
            name: "ChatGPT",
            amount: 20,
            currency: "USD",
            billingPeriod: .monthly,
            nextPaymentDate: date(2026, 6, 9),
            trialStartDate: date(2026, 6, 1),
            trialEndDate: date(2026, 6, 8),
            category: category,
            paymentMethod: method,
            iconName: "chatgpt",
            notes: "Team plan"
        )

        let data = try DataBackupService.backupData(
            subscriptions: [subscription],
            categories: [category],
            paymentMethods: [method]
        )
        let snapshot = try DataBackupService.decodeBackup(data)

        XCTAssertEqual(snapshot.schemaVersion, 1)
        XCTAssertEqual(snapshot.subscriptions.count, 1)
        XCTAssertEqual(snapshot.subscriptions.first?.name, "ChatGPT")
        XCTAssertTrue(Calendar(identifier: .gregorian).isDate(snapshot.subscriptions.first!.trialStartDate!, inSameDayAs: date(2026, 6, 1)))
        XCTAssertTrue(Calendar(identifier: .gregorian).isDate(snapshot.subscriptions.first!.trialEndDate!, inSameDayAs: date(2026, 6, 8)))
        XCTAssertEqual(snapshot.categories.first?.name, "Productivity")
        XCTAssertEqual(snapshot.paymentMethods.first?.name, "Apple Pay")
    }

    func testRestoreReplacesExistingData() throws {
        let originalCategory = Category(name: "Old", colorHex: "#8E8E93", iconName: "archivebox")
        let original = Subscription(
            name: "Old Service",
            amount: 1,
            billingPeriod: .monthly,
            nextPaymentDate: date(2026, 6, 1),
            category: originalCategory
        )

        let restoredCategory = Category(name: "Cloud Storage", colorHex: "#0A84FF", iconName: "cloud")
        let restoredMethod = PaymentMethod(name: "Debit Card", type: "card", colorHex: "#34C759")
        let restored = Subscription(
            name: "iCloud+",
            amount: 2.99,
            currency: "USD",
            billingPeriod: .monthly,
            nextPaymentDate: date(2026, 6, 22),
            trialStartDate: date(2026, 6, 1),
            trialEndDate: date(2026, 6, 21),
            category: restoredCategory,
            paymentMethod: restoredMethod,
            iconName: "icloud"
        )
        let backupData = try DataBackupService.backupData(
            subscriptions: [restored],
            categories: [restoredCategory],
            paymentMethods: [restoredMethod]
        )
        let snapshot = try DataBackupService.decodeBackup(backupData)

        let container = try ModelContainer(
            for: Subscription.self,
            Category.self,
            PaymentMethod.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        context.insert(originalCategory)
        context.insert(original)
        try context.save()

        let restoredSubscriptions = DataBackupService.restore(
            snapshot: snapshot,
            in: context,
            existingSubscriptions: [original],
            existingCategories: [originalCategory],
            existingPaymentMethods: [],
            cancelNotifications: false
        )
        try context.save()

        let subscriptions = try context.fetch(FetchDescriptor<Subscription>())
        let categories = try context.fetch(FetchDescriptor<SubPulse.Category>())
        let methods = try context.fetch(FetchDescriptor<PaymentMethod>())

        XCTAssertEqual(restoredSubscriptions.map(\.name), ["iCloud+"])
        XCTAssertEqual(subscriptions.map(\.name), ["iCloud+"])
        XCTAssertTrue(Calendar(identifier: .gregorian).isDate(subscriptions.first!.trialStartDate!, inSameDayAs: date(2026, 6, 1)))
        XCTAssertTrue(Calendar(identifier: .gregorian).isDate(subscriptions.first!.trialEndDate!, inSameDayAs: date(2026, 6, 21)))
        XCTAssertEqual(categories.map(\.name), ["Cloud Storage"])
        XCTAssertEqual(methods.map(\.name), ["Debit Card"])
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }
}
