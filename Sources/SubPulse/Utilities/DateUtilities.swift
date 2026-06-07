import Foundation

enum DateUtilities {
    static func monthInterval(containing date: Date, calendar: Calendar = .current) -> DateInterval {
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
        let end = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: start) ?? start
        return DateInterval(start: calendar.startOfDay(for: start), end: calendar.endOfDay(for: end))
    }

    static func daysInMonth(containing date: Date, calendar: Calendar = .current) -> [Date] {
        let interval = monthInterval(containing: date, calendar: calendar)
        guard let range = calendar.range(of: .day, in: .month, for: interval.start) else { return [] }
        return range.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: interval.start)
        }
    }

    static func leadingEmptyDays(for date: Date, calendar: Calendar = .current) -> Int {
        let interval = monthInterval(containing: date, calendar: calendar)
        let weekday = calendar.component(.weekday, from: interval.start)
        let firstWeekday = calendar.firstWeekday
        return (weekday - firstWeekday + 7) % 7
    }

    static func isSameDay(_ lhs: Date, _ rhs: Date, calendar: Calendar = .current) -> Bool {
        calendar.isDate(lhs, inSameDayAs: rhs)
    }
}

extension Calendar {
    func endOfDay(for date: Date) -> Date {
        let start = startOfDay(for: date)
        return self.date(byAdding: DateComponents(day: 1, second: -1), to: start) ?? date
    }
}
