import Charts
import SwiftUI

struct InsightCard: View {
    @Environment(\.isSoftNeumorphicTheme) private var isSoftNeumorphic

    let title: String
    let value: String
    let detail: String
    let emoji: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(emoji)
                .font(.title3)
                .frame(width: 36, height: 36)
                .background(Color.accentColor.opacity(0.16), in: RoundedRectangle(cornerRadius: 10))
            Text(title)
                .font(.callout.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .lineLimit(1)
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, minHeight: 132, alignment: .topLeading)
        .padding(18)
        .subPulseRaisedSurface(isSoft: isSoftNeumorphic, cornerRadius: 18)
    }
}

struct MetricCard: View {
    @Environment(\.isSoftNeumorphicTheme) private var isSoftNeumorphic

    let title: String
    let value: String
    var emoji: String = "∑"

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(emoji)
                .font(.title3)
                .frame(width: 36, height: 36)
                .background(Color.accentColor.gradient, in: RoundedRectangle(cornerRadius: 10))
            Text(title)
                .font(.callout)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(.title, design: .rounded, weight: .bold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .subPulseRaisedSurface(isSoft: isSoftNeumorphic, cornerRadius: 18)
    }
}

struct HealthScoreCard: View {
    @Environment(\.isSoftNeumorphicTheme) private var isSoftNeumorphic
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.system.rawValue
    @AppStorage("baseCurrency") private var baseCurrency = "USD"
    @AppStorage("roundingEnabled") private var roundingEnabled = false
    @AppStorage("compactNumbers") private var compactNumbers = false

    let summary: HealthScoreSummary

    private var scoreProgress: CGFloat {
        CGFloat(max(0, min(summary.score, 100))) / 100
    }

    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(.quaternary, lineWidth: 14)
                Circle()
                    .trim(from: 0, to: scoreProgress)
                    .stroke(
                        LinearGradient(
                            colors: [.green, Color.accentColor, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.7, dampingFraction: 0.82), value: summary.score)
                VStack(spacing: 2) {
                    Text("\(summary.score)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())
                    Text("/100")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 112, height: 112)

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(L10n.text("healthScore", language: appLanguage))
                        .font(.title3.bold())
                    Text(L10n.text(summary.statusKey, language: appLanguage))
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(Color.accentColor.opacity(0.14), in: Capsule())
                }

                Text(L10n.text("healthScoreSubtitle", language: appLanguage))
                    .font(.callout)
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    healthPill(String(format: L10n.text("healthDuplicatesFormat", language: appLanguage), summary.duplicateCount))
                    healthPill(String(format: L10n.text("healthExpensiveFormat", language: appLanguage), summary.expensiveCount))
                    healthPill(String(format: L10n.text("healthRisksFormat", language: appLanguage), summary.riskCount))
                    healthPill(String(
                        format: L10n.text("healthSavingsFormat", language: appLanguage),
                        MoneyFormatter.string(summary.savingsAmount, currency: baseCurrency, compact: compactNumbers, rounded: roundingEnabled)
                    ))
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .subPulseRaisedSurface(isSoft: isSoftNeumorphic, cornerRadius: 22)
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(Color.green.opacity(isSoftNeumorphic ? 0.09 : 0.14))
                .frame(width: 180, height: 180)
                .blur(radius: 40)
                .offset(x: 56, y: -72)
        }
    }

    private func healthPill(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .lineLimit(1)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .subPulseInsetSurface(isSoft: isSoftNeumorphic, cornerRadius: 999)
    }
}

struct UpcomingSpendCard: View {
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.system.rawValue
    @AppStorage("baseCurrency") private var baseCurrency = "USD"
    @AppStorage("roundingEnabled") private var roundingEnabled = false
    @AppStorage("compactNumbers") private var compactNumbers = false

    let windows: [UpcomingSpendWindow]

    var body: some View {
        AnalyticsListCard(title: L10n.text("upcomingCharges", language: appLanguage), subtitle: L10n.text("nextWindows", language: appLanguage), emoji: "⏱️") {
            ForEach(windows) { window in
                HStack {
                    Text(String(format: L10n.text("nextDaysFormat", language: appLanguage), window.days))
                        .font(.headline)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(MoneyFormatter.string(window.amount, currency: baseCurrency, compact: compactNumbers, rounded: roundingEnabled))
                            .font(.headline)
                        Text(String(format: L10n.text("chargesCountFormat", language: appLanguage), window.count))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 6)
            }
        }
    }
}

struct GrowthCard: View {
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.system.rawValue
    @AppStorage("baseCurrency") private var baseCurrency = "USD"
    @AppStorage("roundingEnabled") private var roundingEnabled = false
    @AppStorage("compactNumbers") private var compactNumbers = false

    let snapshot: GrowthSnapshot

    private var directionEmoji: String {
        snapshot.difference > 0 ? "📈" : snapshot.difference < 0 ? "📉" : "➖"
    }

    var body: some View {
        AnalyticsListCard(title: L10n.text("spendGrowth", language: appLanguage), subtitle: L10n.text("monthComparison", language: appLanguage), emoji: directionEmoji) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.text("currentMonth", language: appLanguage))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(MoneyFormatter.string(snapshot.currentPeriod, currency: baseCurrency, compact: compactNumbers, rounded: roundingEnabled))
                            .font(.headline)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(L10n.text("previousPeriod", language: appLanguage))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(MoneyFormatter.string(snapshot.previousPeriod, currency: baseCurrency, compact: compactNumbers, rounded: roundingEnabled))
                            .font(.headline)
                    }
                }

                Divider()

                Text(growthText)
                    .font(.callout.weight(.semibold))
                Text(String(format: L10n.text("newSubscriptionsImpactFormat", language: appLanguage), snapshot.newSubscriptionCount, MoneyFormatter.string(snapshot.newImpact, currency: baseCurrency, compact: compactNumbers, rounded: roundingEnabled)))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var growthText: String {
        let amount = MoneyFormatter.string(abs(snapshot.difference), currency: baseCurrency, compact: compactNumbers, rounded: roundingEnabled)
        guard let percent = snapshot.differencePercent else {
            return String(format: L10n.text("growthNoPreviousFormat", language: appLanguage), amount)
        }

        let percentText = percent.formatted(.percent.precision(.fractionLength(0)))
        if snapshot.difference > 0 {
            return String(format: L10n.text("growthUpFormat", language: appLanguage), amount, percentText)
        }
        if snapshot.difference < 0 {
            return String(format: L10n.text("growthDownFormat", language: appLanguage), amount, percentText)
        }
        return L10n.text("growthFlat", language: appLanguage)
    }
}

struct TopSubscriptionsCard: View {
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.system.rawValue
    @AppStorage("baseCurrency") private var baseCurrency = "USD"
    @AppStorage("roundingEnabled") private var roundingEnabled = false
    @AppStorage("compactNumbers") private var compactNumbers = false

    let items: [SubscriptionSpend]

    var body: some View {
        AnalyticsListCard(title: L10n.text("topSubscriptions", language: appLanguage), subtitle: L10n.text("periodRanking", language: appLanguage), emoji: "🏆") {
            if items.isEmpty {
                EmptyAnalyticsText()
            } else {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    HStack(spacing: 10) {
                        Text("#\(index + 1)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                            .frame(width: 30, alignment: .leading)
                        BrandIcon(name: item.name, iconName: item.iconName, colorHex: item.colorHex, size: 30)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name)
                                .font(.headline)
                            Text(L10n.categoryName(item.categoryName, language: appLanguage))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(MoneyFormatter.string(item.amount, currency: baseCurrency, compact: compactNumbers, rounded: roundingEnabled))
                            .font(.headline)
                    }
                    .padding(.vertical, 5)
                }
            }
        }
    }
}

struct ForgottenRiskCard: View {
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.system.rawValue
    @AppStorage("baseCurrency") private var baseCurrency = "USD"
    @AppStorage("roundingEnabled") private var roundingEnabled = false
    @AppStorage("compactNumbers") private var compactNumbers = false

    let items: [ForgottenRisk]

    var body: some View {
        AnalyticsListCard(title: L10n.text("forgottenRisk", language: appLanguage), subtitle: L10n.text("forgottenRiskDescription", language: appLanguage), emoji: "🕵️") {
            if items.isEmpty {
                Text(L10n.text("noRiskFound", language: appLanguage))
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(items) { item in
                    VStack(alignment: .leading, spacing: 7) {
                        HStack {
                            Text(item.name)
                                .font(.headline)
                            Spacer()
                            Text(MoneyFormatter.string(item.amount, currency: baseCurrency, compact: compactNumbers, rounded: roundingEnabled))
                                .font(.headline)
                        }
                        FlowTags(tags: item.reasons.map { L10n.text($0, language: appLanguage) })
                    }
                    .padding(.vertical, 6)
                }
            }
        }
    }
}

struct SavingsScenarioCard: View {
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.system.rawValue
    @AppStorage("baseCurrency") private var baseCurrency = "USD"
    @AppStorage("roundingEnabled") private var roundingEnabled = false
    @AppStorage("compactNumbers") private var compactNumbers = false

    let items: [SavingsScenario]

    var body: some View {
        AnalyticsListCard(title: L10n.text("savingScenarios", language: appLanguage), subtitle: L10n.text("savingScenariosDescription", language: appLanguage), emoji: "✂️") {
            if items.isEmpty {
                EmptyAnalyticsText()
            } else {
                ForEach(items) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(String(format: L10n.text("disableServicesFormat", language: appLanguage), item.title))
                                .font(.headline)
                                .lineLimit(2)
                            Text(L10n.text("periodSaving", language: appLanguage))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("-\(MoneyFormatter.string(item.amount, currency: baseCurrency, compact: compactNumbers, rounded: roundingEnabled))")
                            .font(.headline)
                            .foregroundStyle(.green)
                    }
                    .padding(.vertical, 6)
                }
            }
        }
    }
}

struct AnalyticsListCard<Content: View>: View {
    @Environment(\.isSoftNeumorphicTheme) private var isSoftNeumorphic

    let title: String
    let subtitle: String
    let emoji: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 10) {
                Text(emoji)
                    .font(.title3)
                    .frame(width: 34, height: 34)
                    .background(Color.accentColor.opacity(0.14), in: RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.title3.bold())
                    Text(subtitle)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
            content
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 230, alignment: .topLeading)
        .padding(20)
        .subPulseRaisedSurface(isSoft: isSoftNeumorphic, cornerRadius: 22)
    }
}

struct FlowTags: View {
    @Environment(\.isSoftNeumorphicTheme) private var isSoftNeumorphic

    let tags: [String]

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 6) {
                tagViews
            }
            VStack(alignment: .leading, spacing: 6) {
                tagViews
            }
        }
    }

    @ViewBuilder
    private var tagViews: some View {
        ForEach(tags, id: \.self) { tag in
            Text(tag)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .subPulseInsetSurface(isSoft: isSoftNeumorphic, cornerRadius: 999)
                .foregroundStyle(.secondary)
        }
    }
}

struct EmptyAnalyticsText: View {
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.system.rawValue

    var body: some View {
        Text(L10n.text("addActiveSubscriptions", language: appLanguage))
            .font(.callout)
            .foregroundStyle(.secondary)
    }
}

struct DonutChartCard: View {
    @Environment(\.isSoftNeumorphicTheme) private var isSoftNeumorphic
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.system.rawValue
    @AppStorage("baseCurrency") private var baseCurrency = "USD"
    @AppStorage("roundingEnabled") private var roundingEnabled = false
    @AppStorage("compactNumbers") private var compactNumbers = false

    let spending: [CategorySpend]
    let total: Double
    let progress: Double
    let chartHeight: CGFloat
    let period: AnalyticsPeriod

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.text("categoryMix", language: appLanguage))
                .font(.title3.bold())

            ZStack {
                Chart(spending) { item in
                    SectorMark(
                        angle: .value("Amount", item.amount * progress),
                        innerRadius: .ratio(0.64),
                        angularInset: 2
                    )
                    .cornerRadius(6)
                    .foregroundStyle(Color(hex: item.colorHex).gradient)
                }
                .chartLegend(.hidden)

                VStack(spacing: 4) {
                    Text(MoneyFormatter.string(total, currency: baseCurrency, compact: compactNumbers, rounded: roundingEnabled))
                        .font(.system(.title2, design: .rounded, weight: .bold))
                    Text(period.localizedTitle(language: appLanguage))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(height: chartHeight)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .subPulseRaisedSurface(isSoft: isSoftNeumorphic, cornerRadius: 22)
    }
}

struct CategoryBreakdownCard: View {
    @Environment(\.isSoftNeumorphicTheme) private var isSoftNeumorphic
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.system.rawValue
    @AppStorage("baseCurrency") private var baseCurrency = "USD"
    @AppStorage("roundingEnabled") private var roundingEnabled = false
    @AppStorage("compactNumbers") private var compactNumbers = false

    let spending: [CategorySpend]
    let total: Double
    let progress: Double
    let minHeight: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.text("breakdown", language: appLanguage))
                .font(.title3.bold())

            ForEach(spending) { item in
                let share = total > 0 ? item.amount / total : 0
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Circle()
                            .fill(Color(hex: item.colorHex).gradient)
                            .frame(width: 10, height: 10)
                        Text(L10n.categoryName(item.name, language: appLanguage))
                            .font(.headline)
                        Spacer()
                        Text(MoneyFormatter.string(item.amount, currency: baseCurrency, compact: compactNumbers, rounded: roundingEnabled))
                            .font(.headline)
                        Text(share, format: .percent.precision(.fractionLength(0)))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 44, alignment: .trailing)
                    }

                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(.quaternary)
                            Capsule()
                                .fill(Color(hex: item.colorHex).gradient)
                                .frame(width: max(8, proxy.size.width * share * progress))
                        }
                    }
                    .frame(height: 8)
                }
                .padding(.vertical, 4)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .topLeading)
        .padding(20)
        .subPulseRaisedSurface(isSoft: isSoftNeumorphic, cornerRadius: 22)
    }
}

struct MonthlyProjectionCard: View {
    @Environment(\.isSoftNeumorphicTheme) private var isSoftNeumorphic
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.system.rawValue
    @AppStorage("baseCurrency") private var baseCurrency = "USD"
    @AppStorage("roundingEnabled") private var roundingEnabled = false
    @AppStorage("compactNumbers") private var compactNumbers = false

    let months: [MonthlySpend]
    let progress: Double
    let chartHeight: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.text("monthlyProjection", language: appLanguage))
                        .font(.title3.bold())
                    Text(L10n.text("monthlyProjectionDescription", language: appLanguage))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            Chart(months) { item in
                AreaMark(
                    x: .value("Month", item.month, unit: .month),
                    y: .value("Spend", item.amount * progress)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.accentColor.opacity(0.35), Color.accentColor.opacity(0.04)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)

                LineMark(
                    x: .value("Month", item.month, unit: .month),
                    y: .value("Spend", item.amount * progress)
                )
                .foregroundStyle(Color.accentColor)
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value("Month", item.month, unit: .month),
                    y: .value("Spend", item.amount * progress)
                )
                .foregroundStyle(.background)
                .symbolSize(60)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) { _ in
                    AxisGridLine().foregroundStyle(.clear)
                    AxisValueLabel(format: .dateTime.month(.narrow))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine().foregroundStyle(.quaternary)
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text(MoneyFormatter.string(amount, currency: baseCurrency, compact: compactNumbers, rounded: roundingEnabled))
                        }
                    }
                }
            }
            .frame(height: chartHeight)
        }
        .padding(20)
        .subPulseRaisedSurface(isSoft: isSoftNeumorphic, cornerRadius: 22)
    }
}
