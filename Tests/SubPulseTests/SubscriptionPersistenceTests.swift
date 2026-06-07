import SwiftData
import XCTest
@testable import SubPulse

@MainActor
final class SubscriptionPersistenceTests: XCTestCase {
    func testEditedNextPaymentDatePersistsAfterSaveAndFetch() throws {
        let container = try ModelContainer(
            for: Subscription.self,
            Category.self,
            PaymentMethod.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let subscription = Subscription(
            name: "ChatGPT",
            amount: 20,
            billingPeriod: .monthly,
            nextPaymentDate: date(2026, 6, 9)
        )
        context.insert(subscription)
        try context.save()

        subscription.nextPaymentDate = date(2026, 8, 18)
        subscription.updatedAt = date(2026, 6, 4)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Subscription>())

        XCTAssertEqual(fetched.count, 1)
        XCTAssertTrue(Calendar(identifier: .gregorian).isDate(fetched[0].nextPaymentDate, inSameDayAs: date(2026, 8, 18)))
    }

    func testNextPaymentDatePersistsInLocalStoreAfterReopeningContainer() throws {
        let storeURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("SubPulsePersistence-\(UUID().uuidString)")
            .appendingPathComponent("SubPulse.store")
        try FileManager.default.createDirectory(
            at: storeURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        defer {
            try? FileManager.default.removeItem(at: storeURL.deletingLastPathComponent())
        }

        let schema = Schema([
            Subscription.self,
            Category.self,
            PaymentMethod.self
        ])
        let configuration = ModelConfiguration(schema: schema, url: storeURL)
        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            let context = ModelContext(container)
            let subscription = Subscription(
                name: "Google One",
                amount: 9.99,
                billingPeriod: .monthly,
                nextPaymentDate: date(2026, 9, 24)
            )
            context.insert(subscription)
            try context.save()

            subscription.nextPaymentDate = date(2026, 12, 5)
            try context.save()
        }

        let reopenedContainer = try ModelContainer(for: schema, configurations: [configuration])
        let reopenedContext = ModelContext(reopenedContainer)
        let fetched = try reopenedContext.fetch(FetchDescriptor<Subscription>())

        XCTAssertEqual(fetched.count, 1)
        XCTAssertTrue(Calendar(identifier: .gregorian).isDate(fetched[0].nextPaymentDate, inSameDayAs: date(2026, 12, 5)))
    }

    func testTrialDatesPersistAfterSaveAndFetch() throws {
        let container = try ModelContainer(
            for: Subscription.self,
            Category.self,
            PaymentMethod.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let subscription = Subscription(
            name: "Trial Service",
            amount: 12,
            billingPeriod: .monthly,
            nextPaymentDate: date(2026, 6, 10),
            trialStartDate: date(2026, 6, 1),
            trialEndDate: date(2026, 6, 20)
        )
        context.insert(subscription)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Subscription>())

        XCTAssertEqual(fetched.count, 1)
        XCTAssertTrue(Calendar(identifier: .gregorian).isDate(fetched[0].trialStartDate!, inSameDayAs: date(2026, 6, 1)))
        XCTAssertTrue(Calendar(identifier: .gregorian).isDate(fetched[0].trialEndDate!, inSameDayAs: date(2026, 6, 20)))
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }
}
