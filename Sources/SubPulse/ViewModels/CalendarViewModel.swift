import Foundation
import Observation

@Observable
final class CalendarViewModel {
    var displayedMonth: Date = Date()
    var selectedDate: Date = Date()

    func moveMonth(by value: Int) {
        displayedMonth = Calendar.current.date(byAdding: .month, value: value, to: displayedMonth) ?? displayedMonth
    }

    func occurrences(on date: Date, subscriptions: [Subscription]) -> [PaymentOccurrence] {
        PaymentCalculator.occurrences(for: subscriptions, inMonthContaining: displayedMonth)
            .filter { DateUtilities.isSameDay($0.date, date) }
    }
}
