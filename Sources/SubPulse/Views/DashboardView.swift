import SwiftUI

struct DashboardView: View {
    @Environment(\.isSoftNeumorphicTheme) private var isSoftNeumorphic
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.system.rawValue
    @AppStorage("baseCurrency") private var baseCurrency = "USD"
    @AppStorage("roundingEnabled") private var roundingEnabled = false
    @AppStorage("compactNumbers") private var compactNumbers = false
    @EnvironmentObject private var currencyExchange: CurrencyExchangeService

    let subscriptions: [Subscription]
    let onAdd: (Date?) -> Void
    let onShowAnalytics: () -> Void
    let onShowSettings: () -> Void

    @State private var month = Date()
    @State private var searchText = ""
    @State private var appeared = false
    @State private var selectedDay: DashboardDaySelection?
    @State private var showsSearch = false

    private var monthTotal: Double {
        PaymentCalculator.monthlyTotal(
            for: subscriptions,
            monthDate: month,
            targetCurrency: baseCurrency,
            rates: currencyExchange.rates
        )
    }

    private var occurrences: [PaymentOccurrence] {
        PaymentCalculator.occurrences(for: subscriptions, inMonthContaining: month)
    }

    private var upcomingOccurrences: [PaymentOccurrence] {
        let today = Calendar.current.startOfDay(for: Date())
        return Array(occurrences
            .filter { Calendar.current.startOfDay(for: $0.date) >= today }
            .sorted { $0.date < $1.date }
            .prefix(3))
    }

    private var nextOccurrence: PaymentOccurrence? {
        upcomingOccurrences.first
    }

    private var calendarRowCount: Int {
        let calendar = L10n.calendar(language: appLanguage)
        let leadingDays = DateUtilities.leadingEmptyDays(for: month, calendar: calendar)
        let dayCount = DateUtilities.daysInMonth(containing: month, calendar: calendar).count
        return max(1, Int(ceil(Double(leadingDays + dayCount) / 7.0)))
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .zIndex(2)
            GeometryReader { proxy in
                let layout = dashboardLayout(availableHeight: proxy.size.height)

                dashboardContent(layout: layout)
                    .frame(maxHeight: .infinity, alignment: .top)
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .zIndex(0)
            footerBar
                .zIndex(1)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .background {
            if isSoftNeumorphic {
                Rectangle()
                    .fill(SoftNeumorphicTheme.pageBackground)
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            withAnimation(.smooth(duration: 0.55)) {
                appeared = true
            }
        }
        .animation(.snappy(duration: 0.28), value: monthTotal)
        .animation(.snappy(duration: 0.28), value: month)
        .sheet(item: $selectedDay) { selection in
            DashboardDayDetailsSheet(
                selection: selection,
                language: appLanguage,
                baseCurrency: baseCurrency,
                rates: currencyExchange.rates,
                compactNumbers: compactNumbers,
                roundingEnabled: roundingEnabled,
                onAdd: {
                    selectedDay = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                        onAdd(selection.date)
                    }
                }
            )
        }
        .sheet(isPresented: $showsSearch) {
            DashboardSearchSheet(
                subscriptions: subscriptions,
                searchText: $searchText,
                language: appLanguage,
                baseCurrency: baseCurrency,
                rates: currencyExchange.rates,
                compactNumbers: compactNumbers,
                roundingEnabled: roundingEnabled,
                onAdd: {
                    showsSearch = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                        onAdd(nil)
                    }
                }
            )
            .environment(\.isSoftNeumorphicTheme, isSoftNeumorphic)
        }
    }

    private func dashboardContent(layout: DashboardLayout) -> some View {
        VStack(spacing: layout.sectionSpacing) {
            summary
            if !upcomingOccurrences.isEmpty {
                upcomingStrip
            }
            MiniMonthGrid(
                month: month,
                occurrences: occurrences,
                language: appLanguage,
                baseCurrency: baseCurrency,
                rates: currencyExchange.rates,
                compactNumbers: compactNumbers,
                roundingEnabled: roundingEnabled,
                dayHeight: layout.dayHeight,
                onEmptyDay: { date in onAdd(date) },
                onFilledDay: { selection in selectedDay = selection }
            )
        }
        .frame(maxWidth: 1040)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 28)
        .padding(.vertical, layout.verticalPadding)
    }

    private func dashboardLayout(availableHeight: CGFloat) -> DashboardLayout {
        let rowCount = CGFloat(calendarRowCount)
        let verticalPadding: CGFloat = availableHeight < 610 ? 5 : 8
        let sectionSpacing: CGFloat = availableHeight < 610 ? 7 : 10
        let summaryHeight: CGFloat = 172
        let upcomingHeight: CGFloat = upcomingOccurrences.isEmpty ? 0 : 48
        let weekdayHeaderHeight: CGFloat = 17
        let gridRowSpacing: CGFloat = 8
        let spacingCount: CGFloat = upcomingOccurrences.isEmpty ? 1 : 2

        let fixedHeight = verticalPadding * 2
            + summaryHeight
            + upcomingHeight
            + sectionSpacing * spacingCount
            + weekdayHeaderHeight
            + gridRowSpacing * rowCount
        let fittedDayHeight = floor((availableHeight - fixedHeight) / rowCount)
        let dayHeight = min(78, max(48, fittedDayHeight))

        return DashboardLayout(
            verticalPadding: verticalPadding,
            sectionSpacing: sectionSpacing,
            dayHeight: dayHeight
        )
    }

    private func moveMonth(by offset: Int) {
        let calendar = L10n.calendar(language: appLanguage)
        guard let newMonth = calendar.date(byAdding: .month, value: offset, to: month) else { return }

        withAnimation(.snappy(duration: 0.28)) {
            month = newMonth
        }
    }

    private var header: some View {
        HStack {
            Text(L10n.text("dashboard", language: appLanguage))
                .font(.largeTitle.bold())
            Spacer()
            Button {
                showsSearch = true
            } label: {
                SoftHeaderIcon("🔎", isSoft: isSoftNeumorphic)
            }
            .buttonStyle(.plain)
            .help(L10n.text("search", language: appLanguage))
            Button(action: onShowAnalytics) {
                SoftHeaderIcon("📊", isSoft: isSoftNeumorphic)
            }
            .buttonStyle(.plain)
            .help(L10n.text("stats", language: appLanguage))
            Button(action: onShowSettings) {
                SoftHeaderIcon("⚙️", isSoft: isSoftNeumorphic)
            }
            .buttonStyle(.plain)
            .help(L10n.text("settings", language: appLanguage))
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 18)
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

    private var summary: some View {
        PulseSummaryCard(
            monthTitle: L10n.monthYear(month, language: appLanguage),
            amount: MoneyFormatter.string(monthTotal, currency: baseCurrency, compact: compactNumbers, rounded: roundingEnabled),
            subtitle: "",
            nextText: nextRenewalText,
            countText: String(format: L10n.text("renewalsThisMonthFormat", language: appLanguage), occurrences.count),
            onPreviousMonth: { moveMonth(by: -1) },
            onNextMonth: { moveMonth(by: 1) }
        )
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 14)
    }

    private var nextRenewalText: String {
        guard let nextOccurrence else {
            return L10n.text("noPayments", language: appLanguage)
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let paymentDay = calendar.startOfDay(for: nextOccurrence.date)
        let days = calendar.dateComponents([.day], from: today, to: paymentDay).day ?? 0
        if days <= 0 {
            return L10n.text("dueToday", language: appLanguage)
        }
        return String(format: L10n.text("nextRenewalInDays", language: appLanguage), days)
    }

    private var upcomingStrip: some View {
        return HStack(spacing: 12) {
            ForEach(upcomingOccurrences) { occurrence in
                HStack(spacing: 10) {
                    BrandIcon(
                        name: occurrence.subscription.name,
                        iconName: occurrence.subscription.iconName,
                        colorHex: occurrence.subscription.category?.colorHex ?? "#007AFF",
                        size: 32
                    )
                    VStack(alignment: .leading, spacing: 2) {
                        Text(occurrence.subscription.name)
                            .font(.headline)
                            .lineLimit(1)
                        Text(L10n.shortDate(occurrence.date, language: appLanguage))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(MoneyFormatter.string(
                        currencyExchange.rates.convert(occurrence.amount, from: occurrence.currency, to: baseCurrency),
                        currency: baseCurrency,
                        compact: compactNumbers,
                        rounded: roundingEnabled
                    ))
                        .font(.headline)
                }
                .padding(8)
                .frame(maxWidth: .infinity)
                .subPulseRaisedSurface(isSoft: isSoftNeumorphic, cornerRadius: 16)
                .transition(.scale.combined(with: .opacity))
            }
        }
    }

    private var bottomBar: some View {
        HStack {
            AnimatedAddSubscriptionButton(
                title: L10n.text("addSubscription", language: appLanguage),
                isSoft: isSoftNeumorphic
            ) {
                onAdd(nil)
            }
        }
    }

    private var footerBar: some View {
        bottomBar
            .frame(maxWidth: 1040)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 28)
            .padding(.top, 8)
            .padding(.bottom, 18)
            .background {
                if isSoftNeumorphic {
                    Rectangle()
                        .fill(SoftNeumorphicTheme.pageBackground)
                        .ignoresSafeArea(edges: .bottom)
                }
            }
    }
}

private struct DashboardLayout {
    let verticalPadding: CGFloat
    let sectionSpacing: CGFloat
    let dayHeight: CGFloat
}

private struct AnimatedAddSubscriptionButton: View {
    let title: String
    let isSoft: Bool
    let action: () -> Void

    @State private var isHovering = false
    @State private var pulse = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text("＋")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .rotationEffect(.degrees(isHovering ? 90 : 0))
                    .scaleEffect(isHovering ? 1.12 : (pulse ? 1.04 : 1))
                Text(title)
                    .font(.headline.weight(.bold))
                    .lineLimit(1)
            }
            .foregroundStyle(.white)
            .padding(.vertical, 11)
            .frame(maxWidth: .infinity)
            .background {
                if isSoft {
                    SoftNeumorphicRoundedSurface(
                        depth: isHovering ? .pressed : .raisedSoft,
                        cornerRadius: 18,
                        fill: AnyShapeStyle(Color.accentColor)
                    )
                } else {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.accentColor)
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(.white.opacity(isHovering ? 0.28 : 0.12), lineWidth: 1)
            }
            .shadow(color: Color.accentColor.opacity(isHovering ? 0.26 : 0.16), radius: isHovering ? 18 : 10, y: 7)
            .contentShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
        .scaleEffect(isHovering ? 1.008 : 1)
        .onHover { hovering in
            isHovering = hovering
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.35).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
        .animation(.smooth(duration: 0.2), value: isHovering)
        .accessibilityLabel(title)
    }
}
