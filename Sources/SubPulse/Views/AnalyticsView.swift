import Charts
import SwiftUI

struct AnalyticsView: View {
    @Environment(\.isSoftNeumorphicTheme) private var isSoftNeumorphic
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.system.rawValue
    @AppStorage("baseCurrency") private var baseCurrency = "USD"
    @AppStorage("roundingEnabled") private var roundingEnabled = false
    @AppStorage("compactNumbers") private var compactNumbers = false
    @EnvironmentObject private var currencyExchange: CurrencyExchangeService

    let subscriptions: [Subscription]
    let categories: [Category]

    @State private var viewModel = AnalyticsViewModel()
    @State private var chartProgress = 0.0
    @State private var appeared = false

    private var spending: [CategorySpend] {
        viewModel.categorySpending(for: subscriptions, targetCurrency: baseCurrency, rates: currencyExchange.rates)
    }

    private var monthlyProjection: [MonthlySpend] {
        viewModel.monthlyProjection(for: subscriptions, targetCurrency: baseCurrency, rates: currencyExchange.rates)
    }

    private var yearlyForecast: Double {
        viewModel.yearlyForecast(for: subscriptions, targetCurrency: baseCurrency, rates: currencyExchange.rates)
    }

    private var periodForecast: Double {
        viewModel.periodForecast(for: subscriptions, targetCurrency: baseCurrency, rates: currencyExchange.rates)
    }

    private var topSubscriptions: [SubscriptionSpend] {
        viewModel.topSubscriptions(for: subscriptions, targetCurrency: baseCurrency, rates: currencyExchange.rates)
    }

    private var upcomingWindows: [UpcomingSpendWindow] {
        viewModel.upcomingWindows(for: subscriptions, targetCurrency: baseCurrency, rates: currencyExchange.rates)
    }

    private var growthSnapshot: GrowthSnapshot {
        viewModel.growthSnapshot(for: subscriptions, targetCurrency: baseCurrency, rates: currencyExchange.rates)
    }

    private var forgottenRisks: [ForgottenRisk] {
        viewModel.forgottenRisks(for: subscriptions, targetCurrency: baseCurrency, rates: currencyExchange.rates)
    }

    private var savingsScenarios: [SavingsScenario] {
        viewModel.savingsScenarios(for: subscriptions, targetCurrency: baseCurrency, rates: currencyExchange.rates)
    }

    private var healthScore: HealthScoreSummary {
        viewModel.healthScore(for: subscriptions, targetCurrency: baseCurrency, rates: currencyExchange.rates)
    }

    var body: some View {
        ScrollView {
            content(spacing: 14, chartHeight: 172, breakdownHeight: 214)
                .frame(maxWidth: 980)
                .frame(maxWidth: .infinity)
                .padding(20)
        }
        .navigationTitle(L10n.text("analytics", language: appLanguage))
        .background {
            if isSoftNeumorphic {
                Rectangle()
                    .fill(SoftNeumorphicTheme.pageBackground)
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            animateCharts()
        }
        .onChange(of: viewModel.selectedYear) { _, _ in
            animateCharts()
        }
        .onChange(of: viewModel.selectedCategoryID) { _, _ in
            animateCharts()
        }
        .onChange(of: viewModel.selectedPeriod) { _, _ in
            animateCharts()
        }
    }

    private func content(spacing: CGFloat, chartHeight: CGFloat, breakdownHeight: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: spacing) {
            hero
            filters
            priorityCharts(chartHeight: chartHeight, breakdownHeight: breakdownHeight)
            metrics
            HealthScoreCard(summary: healthScore)
            insightGrid
            detailGrid
        }
    }

    private var hero: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.text("spendIntelligence", language: appLanguage))
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                Text(L10n.text("spendSubtitle", language: appLanguage))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(MoneyFormatter.string(periodForecast, currency: baseCurrency, compact: compactNumbers, rounded: roundingEnabled))
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
                Text(viewModel.selectedPeriod.localizedTitle(language: appLanguage))
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .subPulseRaisedSurface(isSoft: isSoftNeumorphic, cornerRadius: 22)
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(Color.accentColor.opacity(isSoftNeumorphic ? 0.10 : 0.18))
                .frame(width: 180, height: 180)
                .blur(radius: 38)
                .offset(x: 42, y: -54)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 14)
    }

    private var filters: some View {
        HStack {
            Picker(L10n.text("year", language: appLanguage), selection: $viewModel.selectedYear) {
                ForEach((2024...2030), id: \.self) { year in
                    Text(String(year)).tag(year)
                }
            }
            .frame(width: 140)

            Picker(L10n.text("category", language: appLanguage), selection: $viewModel.selectedCategoryID) {
                Text(L10n.text("allCategories", language: appLanguage)).tag(UUID?.none)
                ForEach(categories) { category in
                    Text(L10n.categoryName(category.name, language: appLanguage)).tag(UUID?.some(category.id))
                }
            }
            .frame(width: 220)

            Picker(L10n.text("period", language: appLanguage), selection: $viewModel.selectedPeriod) {
                ForEach(AnalyticsPeriod.allCases) { period in
                    Text(period.localizedTitle(language: appLanguage)).tag(period)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 260)

            Spacer()
        }
    }

    private var metrics: some View {
        Grid(horizontalSpacing: 14, verticalSpacing: 14) {
            GridRow {
                MetricCard(title: L10n.text("periodForecast", language: appLanguage), value: MoneyFormatter.string(periodForecast, currency: baseCurrency, compact: compactNumbers, rounded: roundingEnabled), emoji: "📈")
                MetricCard(title: L10n.text("averageMonth", language: appLanguage), value: MoneyFormatter.string(viewModel.averageMonthlyCost(for: subscriptions, targetCurrency: baseCurrency, rates: currencyExchange.rates), currency: baseCurrency, compact: compactNumbers, rounded: roundingEnabled), emoji: "💳")
                MetricCard(title: L10n.text("activeSubs", language: appLanguage), value: "\(viewModel.activeCount(for: subscriptions))", emoji: "✅")
            }
        }
    }

    private func priorityCharts(chartHeight: CGFloat, breakdownHeight: CGFloat) -> some View {
        LazyVGrid(columns: adaptiveColumns(minimum: 280), spacing: 14) {
            DonutChartCard(spending: spending, total: periodForecast, progress: chartProgress, chartHeight: chartHeight, period: viewModel.selectedPeriod)
                .environment(\.locale, (AppLanguage(rawValue: appLanguage) ?? .system).locale)
            CategoryBreakdownCard(spending: spending, total: periodForecast, progress: chartProgress, minHeight: breakdownHeight)
                .environment(\.locale, (AppLanguage(rawValue: appLanguage) ?? .system).locale)
            MonthlyProjectionCard(months: monthlyProjection, progress: chartProgress, chartHeight: chartHeight)
        }
    }

    private var insightGrid: some View {
        let topSubscription = topSubscriptions.first
        let topCategory = spending.first
        let pairSavings = savingsScenarios.last

        return LazyVGrid(columns: adaptiveColumns(minimum: 240), spacing: 14) {
            InsightCard(
                title: L10n.text("mostExpensiveSubscription", language: appLanguage),
                value: topSubscription?.name ?? L10n.text("noData", language: appLanguage),
                detail: topSubscription.map {
                    MoneyFormatter.string($0.amount, currency: baseCurrency, compact: compactNumbers, rounded: roundingEnabled)
                } ?? L10n.text("addActiveSubscriptions", language: appLanguage),
                emoji: "🔥"
            )
            InsightCard(
                title: L10n.text("mostExpensiveCategory", language: appLanguage),
                value: topCategory.map { L10n.categoryName($0.name, language: appLanguage) } ?? L10n.text("noData", language: appLanguage),
                detail: topCategory.map {
                    MoneyFormatter.string($0.amount, currency: baseCurrency, compact: compactNumbers, rounded: roundingEnabled)
                } ?? L10n.text("addActiveSubscriptions", language: appLanguage),
                emoji: "🧭"
            )
            InsightCard(
                title: L10n.text("savingPotential", language: appLanguage),
                value: pairSavings.map {
                    MoneyFormatter.string($0.amount, currency: baseCurrency, compact: compactNumbers, rounded: roundingEnabled)
                } ?? L10n.text("noData", language: appLanguage),
                detail: pairSavings.map {
                    String(format: L10n.text("disableServicesFormat", language: appLanguage), $0.title)
                } ?? L10n.text("needTwoServices", language: appLanguage),
                emoji: "💡"
            )
        }
    }

    private var detailGrid: some View {
        LazyVGrid(columns: adaptiveColumns(minimum: 320), spacing: 14) {
            UpcomingSpendCard(windows: upcomingWindows)
            GrowthCard(snapshot: growthSnapshot)
            TopSubscriptionsCard(items: Array(topSubscriptions.prefix(5)))
            ForgottenRiskCard(items: Array(forgottenRisks.prefix(5)))
            SavingsScenarioCard(items: savingsScenarios)
        }
    }

    private func adaptiveColumns(minimum: CGFloat) -> [GridItem] {
        [GridItem(.adaptive(minimum: minimum), spacing: 14)]
    }

    private func animateCharts() {
        chartProgress = 0
        withAnimation(.smooth(duration: 0.45)) {
            appeared = true
        }
        withAnimation(.spring(response: 0.75, dampingFraction: 0.82).delay(0.08)) {
            chartProgress = 1
        }
    }
}
