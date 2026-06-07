import XCTest
@testable import SubPulse

final class CurrencyRatesTests: XCTestCase {
    func testConvertBetweenUsdRubAndTry() {
        let rates = CurrencyRates(
            ratesToRub: [
                "RUB": 1,
                "USD": 90,
                "TRY": 3
            ],
            updatedAt: nil
        )

        XCTAssertEqual(rates.convert(10, from: "USD", to: "RUB"), 900, accuracy: 0.001)
        XCTAssertEqual(rates.convert(900, from: "RUB", to: "USD"), 10, accuracy: 0.001)
        XCTAssertEqual(rates.convert(30, from: "TRY", to: "USD"), 1, accuracy: 0.001)
    }

    func testUnknownCurrencyKeepsOriginalAmount() {
        let rates = CurrencyRates(ratesToRub: ["RUB": 1, "USD": 90], updatedAt: nil)

        XCTAssertEqual(rates.convert(42, from: "USD", to: "ABC"), 42, accuracy: 0.001)
    }
}
