import XCTest
@testable import SubPulse

final class PaymentCalculatorTests: XCTestCase {
    private var calendar: Calendar!

    override func setUp() {
        super.setUp()
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    }

    func testMonthlySubscriptionAppearsOnceInMonth() {
        let subscription = Subscription(
            name: "Cloud",
            amount: 9.99,
            billingPeriod: .monthly,
            nextPaymentDate: date(2026, 6, 10)
        )

        let occurrences = PaymentCalculator.occurrences(
            for: subscription,
            inMonthContaining: date(2026, 6, 1),
            calendar: calendar
        )

        XCTAssertEqual(occurrences.map { calendar.component(.day, from: $0.date) }, [10])
        XCTAssertEqual(
            PaymentCalculator.monthlyTotal(for: [subscription], monthDate: date(2026, 6, 1), calendar: calendar),
            9.99,
            accuracy: 0.001
        )
    }

    func testWeeklySubscriptionRepeatsAcrossMonth() {
        let subscription = Subscription(
            name: "Weekly Tool",
            amount: 5,
            billingPeriod: .weekly,
            nextPaymentDate: date(2026, 6, 3)
        )

        let occurrences = PaymentCalculator.occurrences(
            for: subscription,
            inMonthContaining: date(2026, 6, 1),
            calendar: calendar
        )

        XCTAssertEqual(occurrences.map { calendar.component(.day, from: $0.date) }, [3, 10, 17, 24])
        XCTAssertEqual(
            PaymentCalculator.monthlyTotal(for: [subscription], monthDate: date(2026, 6, 1), calendar: calendar),
            20,
            accuracy: 0.001
        )
    }

    func testYearlySubscriptionOnlyAppearsInRenewalMonth() {
        let subscription = Subscription(
            name: "Yearly App",
            amount: 120,
            billingPeriod: .yearly,
            nextPaymentDate: date(2026, 6, 20)
        )

        XCTAssertEqual(
            PaymentCalculator.monthlyTotal(for: [subscription], monthDate: date(2026, 6, 1), calendar: calendar),
            120,
            accuracy: 0.001
        )
        XCTAssertEqual(
            PaymentCalculator.monthlyTotal(for: [subscription], monthDate: date(2026, 7, 1), calendar: calendar),
            0,
            accuracy: 0.001
        )
    }

    func testFutureNextPaymentDateDoesNotCreatePastOccurrences() {
        let subscription = Subscription(
            name: "Future Renewal",
            amount: 15,
            billingPeriod: .monthly,
            nextPaymentDate: date(2026, 8, 18)
        )

        XCTAssertTrue(
            PaymentCalculator.occurrences(
                for: subscription,
                inMonthContaining: date(2026, 6, 1),
                calendar: calendar
            )
            .isEmpty
        )
        XCTAssertEqual(
            PaymentCalculator.monthlyTotal(for: [subscription], monthDate: date(2026, 8, 1), calendar: calendar),
            15,
            accuracy: 0.001
        )
    }

    func testTrialPeriodDefersFirstOccurrenceUntilAfterTrialEnd() {
        let subscription = Subscription(
            name: "Trial App",
            amount: 9.99,
            billingPeriod: .monthly,
            nextPaymentDate: date(2026, 6, 10),
            trialStartDate: date(2026, 6, 1),
            trialEndDate: date(2026, 6, 20)
        )

        let occurrences = PaymentCalculator.occurrences(
            for: subscription,
            inMonthContaining: date(2026, 6, 1),
            calendar: calendar
        )

        XCTAssertEqual(occurrences.map { calendar.component(.day, from: $0.date) }, [21])
        XCTAssertEqual(
            PaymentCalculator.monthlyTotal(for: [subscription], monthDate: date(2026, 6, 1), calendar: calendar),
            9.99,
            accuracy: 0.001
        )
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }
}
