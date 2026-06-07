import SwiftUI

struct CalendarView: View {
    @Environment(\.isSoftNeumorphicTheme) private var isSoftNeumorphic
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.system.rawValue

    let subscriptions: [Subscription]
    @State private var viewModel = CalendarViewModel()

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 7)

    private var monthOccurrences: [PaymentOccurrence] {
        PaymentCalculator.occurrences(for: subscriptions, inMonthContaining: viewModel.displayedMonth)
    }

    private var selectedPayments: [PaymentOccurrence] {
        monthOccurrences.filter { DateUtilities.isSameDay($0.date, viewModel.selectedDate) }
    }

    private var monthTotal: Double {
        monthOccurrences.reduce(0) { $0 + $1.amount }
    }

    private var selectedTotal: Double {
        selectedPayments.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        VStack(spacing: 0) {
            monthToolbar
            GeometryReader { proxy in
                let cellHeight = max(76, min(106, (proxy.size.height - 112) / 6.2))
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 18) {
                        calendarContent(cellHeight: cellHeight)
                            .frame(maxWidth: .infinity)

                        dayPayments
                            .frame(minWidth: 280, idealWidth: 310, maxWidth: 330)
                            .frame(maxHeight: .infinity)
                    }

                    VStack(spacing: 14) {
                        calendarContent(cellHeight: 78)
                        dayPayments
                            .frame(maxHeight: 250)
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle(L10n.text("calendar", language: appLanguage))
        .background {
            if isSoftNeumorphic {
                Rectangle()
                    .fill(SoftNeumorphicTheme.pageBackground)
                    .ignoresSafeArea()
            }
        }
        .animation(.snappy(duration: 0.28), value: viewModel.displayedMonth)
        .animation(.snappy(duration: 0.2), value: viewModel.selectedDate)
    }

    private var monthToolbar: some View {
        HStack(spacing: 14) {
            Button {
                withAnimation { viewModel.moveMonth(by: -1) }
            } label: {
                Text("‹")
                    .font(.title2.bold())
                    .frame(width: 34, height: 30)
            }
            .buttonStyle(.bordered)

            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.monthYear(viewModel.displayedMonth, language: appLanguage))
                    .font(.system(.title2, design: .rounded, weight: .bold))
                Text("\(monthOccurrences.count) \(L10n.text("payments", language: appLanguage))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button {
                withAnimation { viewModel.moveMonth(by: 1) }
            } label: {
                Text("›")
                    .font(.title2.bold())
                    .frame(width: 34, height: 30)
            }
            .buttonStyle(.bordered)

            Spacer()

            Text(MoneyFormatter.string(monthTotal))
                .font(.system(.title3, design: .rounded, weight: .bold))
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background {
            if isSoftNeumorphic {
                SoftNeumorphicTheme.background
                    .ignoresSafeArea()
            } else {
                Rectangle()
                    .fill(.bar)
            }
        }
    }

    private func calendarContent(cellHeight: CGFloat) -> some View {
        VStack(spacing: 14) {
            monthSummary
            calendarGrid(cellHeight: cellHeight)
        }
    }

    private var monthSummary: some View {
        HStack(spacing: 12) {
            CalendarMetric(title: L10n.text("regularMonth", language: appLanguage), value: MoneyFormatter.string(monthTotal), emoji: "💳")
            CalendarMetric(title: L10n.text("payments", language: appLanguage).capitalized, value: "\(monthOccurrences.count)", emoji: "📅")
            CalendarMetric(title: L10n.text("activeSubs", language: appLanguage), value: "\(Set(monthOccurrences.map { $0.subscription.id }).count)", emoji: "✅")
        }
    }

    private func calendarGrid(cellHeight: CGFloat) -> some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(Array(L10n.shortWeekdaySymbols(language: appLanguage).enumerated()), id: \.offset) { index, weekday in
                Text(weekday)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(isWeekendColumn(index) ? Color.red.opacity(0.78) : .secondary)
                    .frame(maxWidth: .infinity)
            }

            ForEach(0..<DateUtilities.leadingEmptyDays(for: viewModel.displayedMonth, calendar: L10n.calendar(language: appLanguage)), id: \.self) { _ in
                Color.clear.frame(height: cellHeight)
            }

            ForEach(DateUtilities.daysInMonth(containing: viewModel.displayedMonth, calendar: L10n.calendar(language: appLanguage)), id: \.self) { date in
                CalendarDayCard(
                    date: date,
                    payments: monthOccurrences.filter { DateUtilities.isSameDay($0.date, date) },
                    isSelected: DateUtilities.isSameDay(date, viewModel.selectedDate),
                    isToday: Calendar.current.isDateInToday(date),
                    isWeekend: L10n.calendar(language: appLanguage).isDateInWeekend(date),
                    height: cellHeight
                ) {
                    viewModel.selectedDate = date
                }
            }
        }
    }

    private func isWeekendColumn(_ index: Int) -> Bool {
        let calendar = L10n.calendar(language: appLanguage)
        let base = Array(1...7)
        let shift = max(calendar.firstWeekday - 1, 0)
        let weekdays = Array(base.dropFirst(shift)) + Array(base.prefix(shift))
        return weekdays.indices.contains(index) && [1, 7].contains(weekdays[index])
    }

    private var dayPayments: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.weekdayDayMonth(viewModel.selectedDate, language: appLanguage))
                    .font(.title3.bold())
                HStack {
                    Text(MoneyFormatter.string(selectedTotal))
                        .font(.system(.title2, design: .rounded, weight: .bold))
                    Spacer()
                    Text("\(selectedPayments.count) \(L10n.text("payments", language: appLanguage))")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.thinMaterial, in: Capsule())
                }
            }

            Divider()

            if selectedPayments.isEmpty {
                ContentUnavailableView(
                    L10n.text("noPayments", language: appLanguage),
                    systemImage: "calendar.badge.checkmark",
                    description: Text(L10n.text("noPaymentsDescription", language: appLanguage))
                )
                .frame(maxWidth: .infinity, minHeight: 180)
            } else {
                ForEach(selectedPayments) { payment in
                    PaymentRow(occurrence: payment)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }

            Spacer(minLength: 20)

            VStack(alignment: .leading, spacing: 10) {
                Text(L10n.text("upcoming", language: appLanguage))
                    .font(.headline)
                ForEach(monthOccurrences.filter { $0.date >= viewModel.selectedDate }.prefix(4)) { payment in
                    HStack(spacing: 10) {
                        BrandIcon(
                            name: payment.subscription.name,
                            iconName: payment.subscription.iconName,
                            colorHex: payment.subscription.category?.colorHex ?? "#007AFF",
                            size: 28
                        )
                        VStack(alignment: .leading, spacing: 1) {
                            Text(payment.subscription.name)
                                .font(.caption.weight(.semibold))
                                .lineLimit(1)
                            Text(L10n.shortDate(payment.date, language: appLanguage))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(MoneyFormatter.string(payment.amount, currency: payment.currency))
                            .font(.caption.weight(.bold))
                    }
                }
            }
        }
        .padding(20)
        .frame(maxHeight: .infinity, alignment: .top)
        .subPulseRaisedSurface(isSoft: isSoftNeumorphic, cornerRadius: 24)
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(.white.opacity(isSoftNeumorphic ? 0 : 0.18), lineWidth: 1)
        }
        .animation(.snappy, value: selectedPayments.count)
    }
}

private struct CalendarMetric: View {
    @Environment(\.isSoftNeumorphicTheme) private var isSoftNeumorphic

    let title: String
    let value: String
    let emoji: String

    var body: some View {
        HStack(spacing: 12) {
            Text(emoji)
                .font(.title3)
                .frame(width: 38, height: 38)
                .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.system(.headline, design: .rounded, weight: .bold))
            }
            Spacer()
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .subPulseRaisedSurface(isSoft: isSoftNeumorphic, cornerRadius: 18)
    }
}

private struct CalendarDayCard: View {
    @Environment(\.isSoftNeumorphicTheme) private var isSoftNeumorphic

    let date: Date
    let payments: [PaymentOccurrence]
    let isSelected: Bool
    let isToday: Bool
    let isWeekend: Bool
    let height: CGFloat
    let onSelect: () -> Void

    @State private var isHovering = false

    private var total: Double {
        payments.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(date.formatted(.dateTime.day()))
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundStyle(isWeekend && !isSelected ? Color.red : (isSelected ? .white : .primary))
                    Spacer()
                    if isToday {
                        Circle()
                            .fill(isSelected ? .white : Color.accentColor)
                            .frame(width: 7, height: 7)
                    }
                }

                if payments.isEmpty {
                    Spacer()
                } else {
                    HStack(spacing: -4) {
                        ForEach(payments.prefix(3)) { payment in
                            BrandIcon(
                                name: payment.subscription.name,
                                iconName: payment.subscription.iconName,
                                colorHex: payment.subscription.category?.colorHex ?? "#007AFF",
                                size: 26
                            )
                        }
                        if payments.count > 3 {
                            Text("+\(payments.count - 3)")
                                .font(.caption2.bold())
                                .frame(width: 26, height: 26)
                                .background(.thinMaterial, in: Circle())
                        }
                    }

                    Text(MoneyFormatter.string(total))
                        .font(.caption.weight(.heavy))
                        .lineLimit(1)

                    Spacer(minLength: 0)
                }
            }
            .padding(12)
            .frame(height: height)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(isSelected ? .white : .primary)
            .background {
                if isSoftNeumorphic {
                    SoftNeumorphicRoundedSurface(
                        depth: softDepth,
                        cornerRadius: 18,
                        fill: softFill
                    )
                } else {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(background)
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(borderColor, lineWidth: isSoftNeumorphic || isSelected ? 0 : 1)
            }
            .scaleEffect(softScale)
            .shadow(color: isSelected ? Color.accentColor.opacity(0.28) : .clear, radius: 18, y: 8)
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .animation(.snappy(duration: 0.18), value: isHovering)
        .animation(.snappy(duration: 0.22), value: isSelected)
    }

    private var softDepth: SoftNeumorphicDepth {
        if isSelected {
            return .pressed
        }
        if payments.isEmpty {
            return isHovering ? .raisedSoft : .inset
        }
        return isHovering ? .pressed : .raisedSoft
    }

    private var softFill: AnyShapeStyle {
        if isSelected {
            return AnyShapeStyle(Color.accentColor.gradient)
        }
        if payments.isEmpty {
            return AnyShapeStyle(isHovering ? SoftNeumorphicTheme.surface : SoftNeumorphicTheme.surfaceInset)
        }
        return AnyShapeStyle(SoftNeumorphicTheme.accentMuted)
    }

    private var softScale: CGFloat {
        guard isSoftNeumorphic else {
            return isHovering || isSelected ? 1.025 : 1
        }
        if isSelected {
            return 0.992
        }
        if payments.isEmpty {
            return isHovering ? 1.01 : 1
        }
        return isHovering ? 0.992 : 1
    }

    private var background: AnyShapeStyle {
        if isSelected {
            return AnyShapeStyle(Color.accentColor.gradient)
        }
        if isSoftNeumorphic {
            if payments.isEmpty {
                return AnyShapeStyle(SoftNeumorphicTheme.surfaceInset)
            }
            return AnyShapeStyle(SoftNeumorphicTheme.accentMuted)
        }
        if payments.isEmpty {
            return AnyShapeStyle(Color(nsColor: .controlBackgroundColor).opacity(0.64))
        }
        return AnyShapeStyle(.regularMaterial)
    }

    private var borderColor: Color {
        if payments.isEmpty {
            return isWeekend ? Color.red.opacity(0.22) : Color.secondary.opacity(0.08)
        }
        return Color.accentColor.opacity(0.24)
    }
}

private struct PaymentRow: View {
    @Environment(\.isSoftNeumorphicTheme) private var isSoftNeumorphic
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.system.rawValue

    let occurrence: PaymentOccurrence

    var body: some View {
        HStack(spacing: 12) {
            BrandIcon(
                name: occurrence.subscription.name,
                iconName: occurrence.subscription.iconName,
                colorHex: occurrence.subscription.category?.colorHex ?? "#007AFF",
                size: 40
            )
            VStack(alignment: .leading, spacing: 2) {
                Text(occurrence.subscription.name)
                    .font(.headline)
                    .lineLimit(1)
                Text(occurrence.subscription.billingPeriod.localizedTitle(language: appLanguage))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Text(MoneyFormatter.string(occurrence.amount, currency: occurrence.currency))
                .font(.headline)
        }
        .padding(12)
        .subPulseInsetSurface(isSoft: isSoftNeumorphic, cornerRadius: 16)
    }
}
