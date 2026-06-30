import Foundation
import SwiftUI
import WidgetKit

private let widgetKind = "SubPulseRenewalsWidget"

@main
struct SubPulseWidgetBundle: WidgetBundle {
    var body: some Widget {
        SubPulseRenewalsWidget()
    }
}

struct SubPulseRenewalsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: widgetKind, provider: SubPulseTimelineProvider()) { entry in
            SubPulseWidgetView(entry: entry)
        }
        .configurationDisplayName("SubPulse")
        .description("Track subscription renewals, monthly spend, and upcoming charges.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

struct SubPulseEntry: TimelineEntry {
    let date: Date
    let snapshot: SubPulseWidgetSnapshot
}

struct SubPulseTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> SubPulseEntry {
        SubPulseEntry(date: Date(), snapshot: .preview)
    }

    func getSnapshot(in context: Context, completion: @escaping (SubPulseEntry) -> Void) {
        completion(SubPulseEntry(date: Date(), snapshot: SubPulseWidgetStore.load() ?? .preview))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SubPulseEntry>) -> Void) {
        let snapshot = SubPulseWidgetStore.load() ?? .preview
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
        completion(Timeline(entries: [SubPulseEntry(date: Date(), snapshot: snapshot)], policy: .after(nextRefresh)))
    }
}

struct SubPulseWidgetView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.colorScheme) private var colorScheme

    let entry: SubPulseEntry

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                small
            case .systemMedium:
                medium
            default:
                large
            }
        }
        .foregroundStyle(WidgetTheme.text(colorScheme))
        .containerBackground(for: .widget) {
            WidgetTheme.background(colorScheme)
        }
    }

    private var small: some View {
        VStack(alignment: .leading, spacing: 8) {
            header(compact: true)
            Spacer(minLength: 0)
            Text(entry.snapshot.monthTotal)
                .font(.system(size: 25, weight: .black, design: .rounded))
                .minimumScaleFactor(0.72)
                .lineLimit(1)
            Text(entry.snapshot.monthTitle)
                .font(.caption.weight(.semibold))
                .foregroundStyle(WidgetTheme.secondaryText(colorScheme))
                .lineLimit(1)
            Spacer(minLength: 0)
            nextPaymentCompact
        }
        .padding(14)
        .widgetRaisedSurface(colorScheme: colorScheme, cornerRadius: 22)
    }

    private var medium: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                header(compact: false)
                Text(entry.snapshot.monthTotal)
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Text(entry.snapshot.renewalCountText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(WidgetTheme.secondaryText(colorScheme))
                    .lineLimit(2)
                Spacer(minLength: 0)
                Text(entry.snapshot.nextText)
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .widgetInsetSurface(colorScheme: colorScheme, cornerRadius: 12)
                    .lineLimit(1)
            }
            .frame(maxWidth: 150, alignment: .leading)

            VStack(spacing: 8) {
                ForEach(Array(entry.snapshot.upcoming.prefix(3)), id: \.id) { payment in
                    paymentRow(payment, dense: true)
                }
                if entry.snapshot.upcoming.isEmpty {
                    emptyState
                }
            }
        }
        .padding(14)
        .widgetRaisedSurface(colorScheme: colorScheme, cornerRadius: 24)
    }

    private var large: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    header(compact: false)
                    Text(entry.snapshot.monthTitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(WidgetTheme.secondaryText(colorScheme))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text(entry.snapshot.monthTotal)
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                    Text(entry.snapshot.renewalCountText)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(WidgetTheme.secondaryText(colorScheme))
                        .lineLimit(1)
                }
            }

            calendarGrid

            VStack(spacing: 7) {
                ForEach(Array(entry.snapshot.upcoming.prefix(3)), id: \.id) { payment in
                    paymentRow(payment, dense: false)
                }
                if entry.snapshot.upcoming.isEmpty {
                    emptyState
                }
            }
        }
        .padding(16)
        .widgetRaisedSurface(colorScheme: colorScheme, cornerRadius: 28)
    }

    private func header(compact: Bool) -> some View {
        HStack(spacing: 7) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: compact ? 11 : 13, weight: .black))
                    .foregroundStyle(.white)
            }
            .frame(width: compact ? 23 : 28, height: compact ? 23 : 28)

            if !compact {
                Text("SubPulse")
                    .font(.headline.weight(.black))
                    .lineLimit(1)
            }
        }
    }

    @ViewBuilder
    private var nextPaymentCompact: some View {
        if let payment = entry.snapshot.nextPayment {
            HStack(spacing: 7) {
                BrandBubble(brand: payment.brand, size: 24)
                VStack(alignment: .leading, spacing: 1) {
                    Text(payment.amount)
                        .font(.caption.bold())
                        .lineLimit(1)
                    Text(payment.relativeDate)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(WidgetTheme.secondaryText(colorScheme))
                        .lineLimit(1)
                }
            }
        } else {
            emptyState
        }
    }

    private func paymentRow(_ payment: SubPulseWidgetPayment, dense: Bool) -> some View {
        HStack(spacing: dense ? 8 : 10) {
            BrandBubble(brand: payment.brand, size: dense ? 28 : 32)
            VStack(alignment: .leading, spacing: 1) {
                Text(payment.name)
                    .font(dense ? .caption.bold() : .subheadline.bold())
                    .lineLimit(1)
                Text(dense ? payment.relativeDate : payment.date)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(WidgetTheme.secondaryText(colorScheme))
                    .lineLimit(1)
            }
            Spacer(minLength: 4)
            Text(payment.amount)
                .font(dense ? .caption.bold() : .subheadline.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(.horizontal, dense ? 8 : 10)
        .padding(.vertical, dense ? 7 : 8)
        .widgetInsetSurface(colorScheme: colorScheme, cornerRadius: 14)
    }

    private var calendarGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

        return VStack(spacing: 5) {
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(entry.snapshot.calendar.weekdaySymbols.prefix(7), id: \.self) { symbol in
                    Text(String(symbol.prefix(2)))
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(WidgetTheme.secondaryText(colorScheme))
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(entry.snapshot.calendar.cells.prefix(42), id: \.id) { cell in
                    CalendarCellView(cell: cell)
                }
            }
        }
        .padding(9)
        .widgetInsetSurface(colorScheme: colorScheme, cornerRadius: 18)
    }

    private var emptyState: some View {
        Text(entry.snapshot.languageCode == "ru" ? "Нет списаний" : "No renewals")
            .font(.caption.weight(.semibold))
            .foregroundStyle(WidgetTheme.secondaryText(colorScheme))
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct CalendarCellView: View {
    @Environment(\.colorScheme) private var colorScheme

    let cell: SubPulseWidgetDay

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(cellBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(cell.isToday ? Color.blue.opacity(0.55) : Color.clear, lineWidth: 1)
                }

            if let day = cell.day {
                VStack(alignment: .leading, spacing: 1) {
                    Text("\(day)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                    Spacer(minLength: 0)
                    if let payment = cell.payments.first {
                        BrandBubble(brand: payment.brand, size: 13)
                    }
                    if let amount = cell.amount {
                        Text(amount)
                            .font(.system(size: 7, weight: .black, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.55)
                    }
                }
                .padding(4)
            }
        }
        .frame(height: 31)
        .opacity(cell.day == nil ? 0 : 1)
    }

    private var cellBackground: Color {
        if !cell.payments.isEmpty {
            return colorScheme == .dark ? Color.blue.opacity(0.22) : Color.blue.opacity(0.11)
        }
        return colorScheme == .dark ? Color.white.opacity(0.04) : Color.white.opacity(0.22)
    }
}

struct BrandBubble: View {
    let brand: SubPulseWidgetBrand
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(Color(hex: brand.backgroundHex).gradient)
                .overlay {
                    Circle()
                        .stroke(.white.opacity(0.35), lineWidth: 0.8)
                }

            if brand.usesOpenAIGlyph {
                ChatGPTKnot(size: size, color: Color(hex: brand.foregroundHex))
            } else {
                Text(brand.mark)
                    .font(.system(size: size * 0.43, weight: .black, design: .rounded))
                    .foregroundStyle(Color(hex: brand.foregroundHex))
                    .minimumScaleFactor(0.55)
            }
        }
        .frame(width: size, height: size)
    }
}

private struct ChatGPTKnot: View {
    let size: CGFloat
    let color: Color

    var body: some View {
        ZStack {
            ForEach(0..<6, id: \.self) { index in
                KnotArm()
                    .stroke(color, style: StrokeStyle(lineWidth: size * 0.06, lineCap: .round, lineJoin: .round))
                    .frame(width: size * 0.62, height: size * 0.62)
                    .rotationEffect(.degrees(Double(index) * 60))
            }

            Circle()
                .stroke(color, lineWidth: size * 0.045)
                .frame(width: size * 0.16, height: size * 0.16)
        }
        .rotationEffect(.degrees(-18))
    }
}

private struct KnotArm: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        path.move(to: CGPoint(x: w * 0.50, y: h * 0.10))
        path.addCurve(
            to: CGPoint(x: w * 0.78, y: h * 0.25),
            control1: CGPoint(x: w * 0.64, y: h * 0.10),
            control2: CGPoint(x: w * 0.74, y: h * 0.15)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.76, y: h * 0.50),
            control1: CGPoint(x: w * 0.86, y: h * 0.36),
            control2: CGPoint(x: w * 0.84, y: h * 0.46)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.55, y: h * 0.58),
            control1: CGPoint(x: w * 0.69, y: h * 0.55),
            control2: CGPoint(x: w * 0.62, y: h * 0.58)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.42, y: h * 0.50),
            control1: CGPoint(x: w * 0.48, y: h * 0.58),
            control2: CGPoint(x: w * 0.44, y: h * 0.55)
        )

        return path
    }
}

private enum SubPulseWidgetStore {
    static var snapshotURLs: [URL] {
        var urls: [URL] = []
        if let supportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            urls.append(
                supportURL
                    .appendingPathComponent("SubPulse", isDirectory: true)
                    .appendingPathComponent("WidgetSnapshot.json")
            )
        }

        urls.append(
            FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Library", isDirectory: true)
                .appendingPathComponent("Application Support", isDirectory: true)
                .appendingPathComponent("SubPulse", isDirectory: true)
                .appendingPathComponent("WidgetSnapshot.json")
        )

        var seen = Set<URL>()
        return urls.filter { seen.insert($0).inserted }
    }

    static func load() -> SubPulseWidgetSnapshot? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        for snapshotURL in snapshotURLs {
            guard let data = try? Data(contentsOf: snapshotURL),
                  let snapshot = try? decoder.decode(SubPulseWidgetSnapshot.self, from: data)
            else {
                continue
            }
            return snapshot
        }
        return nil
    }
}

private enum WidgetTheme {
    static func background(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.10, green: 0.13, blue: 0.17) : Color(red: 0.88, green: 0.92, blue: 0.96)
    }

    static func surface(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.12, green: 0.15, blue: 0.19) : Color(red: 0.88, green: 0.92, blue: 0.96)
    }

    static func text(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.91, green: 0.94, blue: 0.98) : Color(red: 0.12, green: 0.14, blue: 0.18)
    }

    static func secondaryText(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.58) : Color(red: 0.43, green: 0.48, blue: 0.56)
    }

    static func lightShadow(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.88)
    }

    static func darkShadow(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.black.opacity(0.55) : Color(red: 0.62, green: 0.68, blue: 0.76).opacity(0.62)
    }
}

private extension View {
    func widgetRaisedSurface(colorScheme: ColorScheme, cornerRadius: CGFloat) -> some View {
        background {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(WidgetTheme.surface(colorScheme))
                .shadow(color: WidgetTheme.darkShadow(colorScheme), radius: 16, x: 11, y: 11)
                .shadow(color: WidgetTheme.lightShadow(colorScheme), radius: 14, x: -9, y: -9)
        }
    }

    func widgetInsetSurface(colorScheme: ColorScheme, cornerRadius: CGFloat) -> some View {
        background {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(WidgetTheme.surface(colorScheme))
                .shadow(color: WidgetTheme.darkShadow(colorScheme), radius: 7, x: 4, y: 4)
                .shadow(color: WidgetTheme.lightShadow(colorScheme), radius: 6, x: -4, y: -4)
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(WidgetTheme.lightShadow(colorScheme).opacity(0.6), lineWidth: 0.6)
                }
        }
    }
}

private extension Color {
    init(hex: String) {
        let trimmed = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: trimmed).scanHexInt64(&value)

        let red: Double
        let green: Double
        let blue: Double

        switch trimmed.count {
        case 6:
            red = Double((value >> 16) & 0xFF) / 255
            green = Double((value >> 8) & 0xFF) / 255
            blue = Double(value & 0xFF) / 255
        default:
            red = 0.05
            green = 0.45
            blue = 1.0
        }

        self.init(red: red, green: green, blue: blue)
    }
}

struct SubPulseWidgetSnapshot: Codable {
    let generatedAt: Date
    let languageCode: String
    let baseCurrency: String
    let monthTitle: String
    let monthTotal: String
    let renewalCount: Int
    let renewalCountText: String
    let nextText: String
    let nextPayment: SubPulseWidgetPayment?
    let upcoming: [SubPulseWidgetPayment]
    let calendar: SubPulseWidgetCalendar

    static let placeholder = SubPulseWidgetSnapshot(
        generatedAt: Date(),
        languageCode: "en",
        baseCurrency: "USD",
        monthTitle: "June 2026",
        monthTotal: "$112.98",
        renewalCount: 3,
        renewalCountText: "3 renewals this month",
        nextText: "Next in 5 days",
        nextPayment: SubPulseWidgetPayment(
            id: "chatgpt",
            name: "ChatGPT",
            amount: "$100",
            date: "Jun 4, 2026",
            dayNumber: 4,
            relativeDate: "Today",
            brand: SubPulseWidgetBrand(mark: "", backgroundHex: "#FFFFFF", foregroundHex: "#111111", usesOpenAIGlyph: true)
        ),
        upcoming: [
            SubPulseWidgetPayment(
                id: "chatgpt",
                name: "ChatGPT",
                amount: "$100",
                date: "Jun 4, 2026",
                dayNumber: 4,
                relativeDate: "Today",
                brand: SubPulseWidgetBrand(mark: "", backgroundHex: "#FFFFFF", foregroundHex: "#111111", usesOpenAIGlyph: true)
            ),
            SubPulseWidgetPayment(
                id: "icloud",
                name: "iCloud+",
                amount: "$2.99",
                date: "Jun 22, 2026",
                dayNumber: 22,
                relativeDate: "In 18d",
                brand: SubPulseWidgetBrand(mark: "☁", backgroundHex: "#2E7AFF", foregroundHex: "#FFFFFF", usesOpenAIGlyph: false)
            ),
            SubPulseWidgetPayment(
                id: "google",
                name: "Google One",
                amount: "$9.99",
                date: "Jun 25, 2026",
                dayNumber: 25,
                relativeDate: "In 21d",
                brand: SubPulseWidgetBrand(mark: "G", backgroundHex: "#FFFFFF", foregroundHex: "#2D6CDF", usesOpenAIGlyph: false)
            )
        ],
        calendar: SubPulseWidgetCalendar(weekdaySymbols: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"], cells: [])
    )

    static var preview: SubPulseWidgetSnapshot {
        let payments = placeholder.upcoming
        let cells = (1...30).map { day in
            let payment: SubPulseWidgetPayment?
            if day == 4 {
                payment = payments[0]
            } else if day == 22 {
                payment = payments[1]
            } else if day == 25 {
                payment = payments[2]
            } else {
                payment = nil
            }

            return SubPulseWidgetDay(
                id: "placeholder-\(day)",
                day: day,
                isToday: day == 4,
                amount: payment?.amount,
                payments: payment.map { [$0] } ?? []
            )
        }

        return SubPulseWidgetSnapshot(
            generatedAt: placeholder.generatedAt,
            languageCode: placeholder.languageCode,
            baseCurrency: placeholder.baseCurrency,
            monthTitle: placeholder.monthTitle,
            monthTotal: placeholder.monthTotal,
            renewalCount: placeholder.renewalCount,
            renewalCountText: placeholder.renewalCountText,
            nextText: placeholder.nextText,
            nextPayment: placeholder.nextPayment,
            upcoming: placeholder.upcoming,
            calendar: SubPulseWidgetCalendar(weekdaySymbols: placeholder.calendar.weekdaySymbols, cells: cells)
        )
    }
}

struct SubPulseWidgetCalendar: Codable {
    let weekdaySymbols: [String]
    let cells: [SubPulseWidgetDay]
}

struct SubPulseWidgetDay: Codable {
    let id: String
    let day: Int?
    let isToday: Bool
    let amount: String?
    let payments: [SubPulseWidgetPayment]
}

struct SubPulseWidgetPayment: Codable {
    let id: String
    let name: String
    let amount: String
    let date: String
    let dayNumber: Int
    let relativeDate: String
    let brand: SubPulseWidgetBrand
}

struct SubPulseWidgetBrand: Codable {
    let mark: String
    let backgroundHex: String
    let foregroundHex: String
    let usesOpenAIGlyph: Bool
}
