import XCTest
@testable import SubPulse

final class AnalyticsViewModelTests: XCTestCase {
    private var calendar: Calendar!

    override func setUp() {
        super.setUp()
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    }

    func testSelectedPeriodChangesForecastAndTopSubscriptionAmounts() {
        let chatGPT = Subscription(
            name: "ChatGPT",
            amount: 20,
            currency: "USD",
            billingPeriod: .monthly,
            nextPaymentDate: date(2026, 6, 9)
        )
        let annualTool = Subscription(
            name: "Annual Tool",
            amount: 100,
            currency: "USD",
            billingPeriod: .yearly,
            nextPaymentDate: date(2026, 8, 1)
        )
        let viewModel = AnalyticsViewModel()
        viewModel.referenceDate = date(2026, 6, 3)
        viewModel.selectedYear = 2026

        viewModel.selectedPeriod = .month
        XCTAssertEqual(
            viewModel.periodForecast(for: [chatGPT, annualTool], targetCurrency: "USD", rates: .fallback),
            20,
            accuracy: 0.001
        )
        XCTAssertEqual(
            viewModel.topSubscriptions(for: [chatGPT, annualTool], targetCurrency: "USD", rates: .fallback).first?.amount ?? -1,
            20,
            accuracy: 0.001
        )

        viewModel.selectedPeriod = .sixMonths
        XCTAssertEqual(
            viewModel.periodForecast(for: [chatGPT, annualTool], targetCurrency: "USD", rates: .fallback),
            220,
            accuracy: 0.001
        )
        XCTAssertEqual(
            viewModel.topSubscriptions(for: [chatGPT, annualTool], targetCurrency: "USD", rates: .fallback).first?.name,
            "ChatGPT"
        )

        viewModel.selectedPeriod = .year
        XCTAssertEqual(
            viewModel.periodForecast(for: [chatGPT, annualTool], targetCurrency: "USD", rates: .fallback),
            240,
            accuracy: 0.001
        )
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }
}
