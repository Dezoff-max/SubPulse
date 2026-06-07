import SwiftUI

struct PulseSummaryCard: View {
    @Environment(\.isSoftNeumorphicTheme) private var isSoftNeumorphic

    let monthTitle: String
    let amount: String
    let subtitle: String
    let nextText: String
    let countText: String
    let onPreviousMonth: () -> Void
    let onNextMonth: () -> Void

    var body: some View {
        ZStack {
            PulseHalo()
                .frame(width: 280, height: 130)
                .opacity(0.95)

            HStack {
                MonthArrowButton(symbol: "chevron.left", action: onPreviousMonth)
                    .padding(.leading, 24)
                Spacer()
                MonthArrowButton(symbol: "chevron.right", action: onNextMonth)
                    .padding(.trailing, 24)
            }

            VStack(spacing: 8) {
                Text(monthTitle)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                Text(amount)
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(minHeight: 54)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 8) {
                    PulseChip(text: nextText, icon: "⏱")
                    PulseChip(text: countText, icon: "✦")
                }
                .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 172)
        .subPulseRaisedSurface(isSoft: isSoftNeumorphic, cornerRadius: 28)
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(Color.accentColor.opacity(isSoftNeumorphic ? 0.10 : 0.16))
                .frame(width: 170, height: 170)
                .blur(radius: 42)
                .offset(x: 38, y: -62)
                .allowsHitTesting(false)
        }
    }
}

private struct MonthArrowButton: View {
    @Environment(\.isSoftNeumorphicTheme) private var isSoftNeumorphic

    let symbol: String
    let action: () -> Void

    @State private var isHovering = false
    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.accentColor)
                .frame(width: 42, height: 42)
                .background {
                    if isSoftNeumorphic {
                        SoftNeumorphicRoundedSurface(
                            depth: isHovering ? .pressed : .raisedSoft,
                            cornerRadius: 16,
                            fill: AnyShapeStyle(isHovering ? SoftNeumorphicTheme.surfaceInset : SoftNeumorphicTheme.surface)
                        )
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.regularMaterial)
                    }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.accentColor.opacity(isHovering ? 0.30 : 0.12), lineWidth: 1)
                }
                .contentShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .scaleEffect(isHovering ? 1.04 : 1)
        .onHover { isHovering = $0 }
        .animation(.smooth(duration: 0.18), value: isHovering)
    }
}

struct PulseChip: View {
    @Environment(\.isSoftNeumorphicTheme) private var isSoftNeumorphic

    let text: String
    let icon: String

    var body: some View {
        HStack(spacing: 5) {
            Text(icon)
            Text(text)
                .lineLimit(1)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .subPulseInsetSurface(isSoft: isSoftNeumorphic, cornerRadius: 999)
    }
}

struct PulseHalo: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let baseRadius = min(size.width, size.height) * 0.28

                for index in 0..<3 {
                    let phase = (sin(time * 1.35 + Double(index) * 1.2) + 1) / 2
                    let radius = baseRadius + CGFloat(index) * 22 + CGFloat(phase) * 8
                    let opacity = 0.24 - Double(index) * 0.055
                    let rect = CGRect(
                        x: center.x - radius,
                        y: center.y - radius,
                        width: radius * 2,
                        height: radius * 2
                    )
                    context.stroke(
                        Path(ellipseIn: rect),
                        with: .color(Color.accentColor.opacity(opacity)),
                        lineWidth: 2
                    )
                }

                let angle = time * 0.9
                let orbitRadius = baseRadius + 42
                let point = CGPoint(
                    x: center.x + cos(angle) * orbitRadius,
                    y: center.y + sin(angle) * orbitRadius * 0.62
                )
                let dotRect = CGRect(x: point.x - 4, y: point.y - 4, width: 8, height: 8)
                context.fill(Path(ellipseIn: dotRect), with: .color(Color.accentColor.opacity(0.85)))
                context.addFilter(.blur(radius: 9))
                context.fill(Path(ellipseIn: dotRect.insetBy(dx: -8, dy: -8)), with: .color(Color.accentColor.opacity(0.24)))
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct DashboardDaySelection: Identifiable {
    let date: Date
    let payments: [PaymentOccurrence]

    var id: TimeInterval { date.timeIntervalSince1970 }
}

struct MiniMonthGrid: View {
    let month: Date
    let occurrences: [PaymentOccurrence]
    let language: String
    let baseCurrency: String
    let rates: CurrencyRates
    let compactNumbers: Bool
    let roundingEnabled: Bool
    let dayHeight: CGFloat
    let onEmptyDay: (Date) -> Void
    let onFilledDay: (DashboardDaySelection) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(Array(L10n.shortWeekdaySymbols(language: language).enumerated()), id: \.offset) { index, weekday in
                Text(weekday)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isWeekendColumn(index) ? Color.red.opacity(0.78) : .secondary)
                    .frame(maxWidth: .infinity)
            }

            ForEach(0..<DateUtilities.leadingEmptyDays(for: month, calendar: L10n.calendar(language: language)), id: \.self) { _ in
                Color.clear
                    .frame(height: dayHeight)
            }

            ForEach(DateUtilities.daysInMonth(containing: month, calendar: L10n.calendar(language: language)), id: \.self) { date in
                let dayOccurrences = occurrences.filter { DateUtilities.isSameDay($0.date, date) }
                MiniDayCell(
                    date: date,
                    occurrences: Array(dayOccurrences),
                    isWeekend: L10n.calendar(language: language).isDateInWeekend(date),
                    baseCurrency: baseCurrency,
                    rates: rates,
                    compactNumbers: compactNumbers,
                    roundingEnabled: roundingEnabled,
                    height: dayHeight
                ) {
                    if dayOccurrences.isEmpty {
                        onEmptyDay(date)
                    } else {
                        onFilledDay(DashboardDaySelection(date: date, payments: Array(dayOccurrences)))
                    }
                }
            }
        }
    }

    private func isWeekendColumn(_ index: Int) -> Bool {
        let weekdays = orderedWeekdayNumbers(calendar: L10n.calendar(language: language))
        return weekdays.indices.contains(index) && [1, 7].contains(weekdays[index])
    }

    private func orderedWeekdayNumbers(calendar: Calendar) -> [Int] {
        let base = Array(1...7)
        let shift = max(calendar.firstWeekday - 1, 0)
        return Array(base.dropFirst(shift)) + Array(base.prefix(shift))
    }
}

struct MiniDayCell: View {
    @Environment(\.isSoftNeumorphicTheme) private var isSoftNeumorphic

    let date: Date
    let occurrences: [PaymentOccurrence]
    let isWeekend: Bool
    let baseCurrency: String
    let rates: CurrencyRates
    let compactNumbers: Bool
    let roundingEnabled: Bool
    let height: CGFloat
    let onTap: () -> Void

    @State private var appeared = false
    @State private var hovering = false

    private var total: Double {
        occurrences.reduce(0) { total, occurrence in
            total + rates.convert(occurrence.amount, from: occurrence.currency, to: baseCurrency)
        }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: cellSpacing) {
                HStack(alignment: .top) {
                    Text(date.formatted(.dateTime.day()))
                        .font(dayFont)
                        .foregroundStyle(isWeekend ? Color.red : .primary)
                    Spacer()
                    if occurrences.isEmpty {
                        Text("＋")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary.opacity(hovering ? 0.95 : 0.42))
                    }
                }

                if occurrences.isEmpty {
                    Spacer(minLength: 0)
                } else {
                    HStack(spacing: -5) {
                        ForEach(occurrences.prefix(3)) { occurrence in
                            BrandIcon(
                                name: occurrence.subscription.name,
                                iconName: occurrence.subscription.iconName,
                                colorHex: occurrence.subscription.category?.colorHex ?? "#007AFF",
                                size: iconSize
                            )
                            .scaleEffect(appeared ? 1 : 0.5)
                            .transition(.scale.combined(with: .opacity))
                        }
                    }

                    Text(MoneyFormatter.string(total, currency: baseCurrency, compact: compactNumbers, rounded: roundingEnabled))
                        .font(amountFont)
                        .lineLimit(1)
                }
            }
            .padding(cellPadding)
            .frame(height: height)
            .frame(maxWidth: .infinity, alignment: .leading)
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
                RoundedRectangle(cornerRadius: 16)
                    .stroke(borderColor, lineWidth: isSoftNeumorphic ? 0 : (occurrences.isEmpty ? 1 : 1.5))
            }
            .shadow(color: occurrences.isEmpty ? .clear : Color.accentColor.opacity(0.14), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
        .scaleEffect(softScale)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 8)
        .onHover { hovering = $0 }
        .onAppear {
            withAnimation(.smooth(duration: 0.35).delay(Double(Calendar.current.component(.day, from: date)) * 0.008)) {
                appeared = true
            }
        }
        .animation(.snappy(duration: 0.18), value: hovering)
    }

    private var isCompact: Bool {
        height < 62
    }

    private var cellPadding: CGFloat {
        isCompact ? 7 : 10
    }

    private var cellSpacing: CGFloat {
        isCompact ? 3 : 5
    }

    private var iconSize: CGFloat {
        isCompact ? 18 : 22
    }

    private var dayFont: Font {
        isCompact
            ? .system(.subheadline, design: .rounded, weight: .bold)
            : .system(.headline, design: .rounded, weight: .bold)
    }

    private var amountFont: Font {
        isCompact ? .caption2.weight(.heavy) : .caption.weight(.heavy)
    }

    private var softDepth: SoftNeumorphicDepth {
        if occurrences.isEmpty {
            return hovering ? .raisedSoft : .inset
        }
        return hovering ? .pressed : .raisedSoft
    }

    private var softFill: AnyShapeStyle {
        if occurrences.isEmpty {
            return AnyShapeStyle(hovering ? SoftNeumorphicTheme.surface : SoftNeumorphicTheme.surfaceInset)
        }
        return AnyShapeStyle(SoftNeumorphicTheme.accentMuted)
    }

    private var softScale: CGFloat {
        guard isSoftNeumorphic else {
            return hovering ? 1.012 : 1
        }
        if occurrences.isEmpty {
            return hovering ? 1.01 : 1
        }
        return hovering ? 0.992 : 1
    }

    private var background: AnyShapeStyle {
        if isSoftNeumorphic {
            if occurrences.isEmpty {
                return AnyShapeStyle(SoftNeumorphicTheme.surfaceInset)
            }
            return AnyShapeStyle(SoftNeumorphicTheme.accentMuted)
        }
        if occurrences.isEmpty {
            return AnyShapeStyle(.regularMaterial)
        }
        return AnyShapeStyle(Color.accentColor.opacity(0.10).gradient)
    }

    private var borderColor: Color {
        if !occurrences.isEmpty {
            return Color.accentColor.opacity(0.38)
        }
        return isWeekend ? Color.red.opacity(0.22) : Color.secondary.opacity(0.12)
    }
}

struct DashboardDayDetailsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isSoftNeumorphicTheme) private var isSoftNeumorphic

    let selection: DashboardDaySelection
    let language: String
    let baseCurrency: String
    let rates: CurrencyRates
    let compactNumbers: Bool
    let roundingEnabled: Bool
    let onAdd: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.text("dayDetails", language: language))
                        .font(.title2.bold())
                    Text(L10n.shortDate(selection.date, language: language))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("➕ \(L10n.text("chooseSubscription", language: language))", action: onAdd)
                Button {
                    dismiss()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 18, height: 18)
                        Image(systemName: "xmark")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.white.opacity(0.92))
                    }
                }
                .buttonStyle(.plain)
                .padding(.top, 3)
                .help(L10n.text("close", language: language))
            }

            ForEach(selection.payments) { payment in
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 12) {
                        BrandIcon(
                            name: payment.subscription.name,
                            iconName: payment.subscription.iconName,
                            colorHex: payment.subscription.category?.colorHex ?? "#007AFF",
                            size: 44
                        )
                        VStack(alignment: .leading, spacing: 2) {
                            Text(payment.subscription.name)
                                .font(.headline)
                            Text(payment.subscription.billingPeriod.localizedTitle(language: language))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(MoneyFormatter.string(
                            rates.convert(payment.amount, from: payment.currency, to: baseCurrency),
                            currency: baseCurrency,
                            compact: compactNumbers,
                            rounded: roundingEnabled
                        ))
                            .font(.title3.bold())
                    }

                    if let category = payment.subscription.category {
                        Label(L10n.categoryName(category.name, language: language), systemImage: "tag")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let method = payment.subscription.paymentMethod {
                        let methodName = L10n.paymentMethodName(method.name, language: language)
                        Label(method.last4.map { "\(methodName) •••• \($0)" } ?? methodName, systemImage: "creditcard")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if !payment.subscription.notes.isEmpty {
                        Text(payment.subscription.notes)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(14)
                .subPulseRaisedSurface(isSoft: isSoftNeumorphic, cornerRadius: 18)
            }
        }
        .padding(22)
        .frame(width: 460)
    }
}

struct SoftHeaderIcon: View {
    let emoji: String
    let isSoft: Bool

    init(_ emoji: String, isSoft: Bool) {
        self.emoji = emoji
        self.isSoft = isSoft
    }

    var body: some View {
        Text(emoji)
            .font(.system(size: 15, weight: .semibold))
            .frame(width: 34, height: 30)
            .contentShape(RoundedRectangle(cornerRadius: 11))
            .subPulseRaisedSurface(
                isSoft: isSoft,
                cornerRadius: 11,
                fallback: AnyShapeStyle(Color(nsColor: .controlBackgroundColor).opacity(0.72))
            )
    }
}

struct DashboardSearchSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isSoftNeumorphicTheme) private var isSoftNeumorphic

    let subscriptions: [Subscription]
    @Binding var searchText: String
    let language: String
    let baseCurrency: String
    let rates: CurrencyRates
    let compactNumbers: Bool
    let roundingEnabled: Bool
    let onAdd: () -> Void

    private var results: [Subscription] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let source = subscriptions.sorted { $0.billableNextPaymentDate() < $1.billableNextPaymentDate() }
        guard !query.isEmpty else { return source }
        return source.filter { subscription in
            subscription.name.localizedCaseInsensitiveContains(query) ||
                subscription.currency.localizedCaseInsensitiveContains(query) ||
                (subscription.category.map { L10n.categoryName($0.name, language: language).localizedCaseInsensitiveContains(query) } ?? false) ||
                (subscription.paymentMethod.map { L10n.paymentMethodName($0.name, language: language).localizedCaseInsensitiveContains(query) } ?? false)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.text("searchSubscriptions", language: language))
                        .font(.title.bold())
                    Text(L10n.text("searchSubscriptionsHint", language: language))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    dismiss()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 18, height: 18)
                        Image(systemName: "xmark")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.white.opacity(0.92))
                    }
                }
                .buttonStyle(.plain)
                .help(L10n.text("close", language: language))
            }

            HStack(spacing: 10) {
                Text("🔎")
                TextField(L10n.text("search", language: language), text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .subPulseInsetSurface(
                isSoft: isSoftNeumorphic,
                cornerRadius: 18,
                fallback: AnyShapeStyle(Color(nsColor: .controlBackgroundColor))
            )

            ScrollView {
                LazyVStack(spacing: 10) {
                    if results.isEmpty {
                        ContentUnavailableView(
                            L10n.text("noData", language: language),
                            systemImage: "magnifyingglass",
                            description: Text(L10n.text("searchNoResults", language: language))
                        )
                        .padding(.vertical, 42)
                    } else {
                        ForEach(results) { subscription in
                            SearchResultRow(
                                subscription: subscription,
                                language: language,
                                baseCurrency: baseCurrency,
                                rates: rates,
                                compactNumbers: compactNumbers,
                                roundingEnabled: roundingEnabled
                            )
                        }
                    }
                }
                .padding(.vertical, 2)
            }

            HStack {
                Text(String(format: L10n.text("searchResultsFormat", language: language), results.count))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    onAdd()
                } label: {
                    Label(L10n.text("addSubscription", language: language), systemImage: "plus")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(22)
        .frame(width: 520, height: 560)
        .background {
            if isSoftNeumorphic {
                Rectangle()
                    .fill(SoftNeumorphicTheme.pageBackground)
                    .ignoresSafeArea()
            } else {
                Color(nsColor: .windowBackgroundColor)
                    .ignoresSafeArea()
            }
        }
    }
}

private struct SearchResultRow: View {
    @Environment(\.isSoftNeumorphicTheme) private var isSoftNeumorphic

    let subscription: Subscription
    let language: String
    let baseCurrency: String
    let rates: CurrencyRates
    let compactNumbers: Bool
    let roundingEnabled: Bool

    var body: some View {
        HStack(spacing: 12) {
            BrandIcon(
                name: subscription.name,
                iconName: subscription.iconName,
                colorHex: subscription.category?.colorHex ?? "#007AFF",
                size: 38
            )
            VStack(alignment: .leading, spacing: 3) {
                Text(subscription.name)
                    .font(.headline)
                    .lineLimit(1)
                Text("\(subscription.billingPeriod.localizedTitle(language: language)) · \(L10n.shortDate(subscription.billableNextPaymentDate(), language: language))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let category = subscription.category {
                    Text(L10n.categoryName(category.name, language: language))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text(MoneyFormatter.string(
                rates.convert(subscription.amount, from: subscription.currency, to: baseCurrency),
                currency: baseCurrency,
                compact: compactNumbers,
                rounded: roundingEnabled
            ))
            .font(.headline)
            .monospacedDigit()
        }
        .padding(12)
        .subPulseRaisedSurface(
            isSoft: isSoftNeumorphic,
            cornerRadius: 18,
            fallback: AnyShapeStyle(Color(nsColor: .controlBackgroundColor))
        )
    }
}
