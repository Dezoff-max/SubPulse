import SwiftData
@testable import SubPulse
import XCTest

final class SeedServiceTests: XCTestCase {
    @MainActor
    func testDemoSubscriptionsDoNotReturnAfterResetMarker() throws {
        SeedService.clearDemoSeedMarkerForTests()
        defer {
            SeedService.clearDemoSeedMarkerForTests()
        }

        SeedService.markAllDataResetCompleted()

        let container = try ModelContainer(
            for: Subscription.self,
            SubPulse.Category.self,
            PaymentMethod.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        SeedService.seedIfNeeded(in: context)

        let subscriptionCount = try context.fetchCount(FetchDescriptor<Subscription>())
        XCTAssertEqual(subscriptionCount, 0)

        let categoryCount = try context.fetchCount(FetchDescriptor<SubPulse.Category>())
        let paymentMethodCount = try context.fetchCount(FetchDescriptor<PaymentMethod>())
        XCTAssertEqual(categoryCount, 0)
        XCTAssertEqual(paymentMethodCount, 0)
    }
}
