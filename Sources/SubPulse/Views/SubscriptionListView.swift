import SwiftData
import SwiftUI

struct SubscriptionListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.isSoftNeumorphicTheme) private var isSoftNeumorphic
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.system.rawValue
    @AppStorage("baseCurrency") private var baseCurrency = "USD"
    @AppStorage("roundingEnabled") private var roundingEnabled = false
    @AppStorage("compactNumbers") private var compactNumbers = false
    @EnvironmentObject private var currencyExchange: CurrencyExchangeService

    let subscriptions: [Subscription]
    let onAdd: () -> Void
    let onEdit: (Subscription) -> Void
    let onDelete: (Subscription) -> Void

    @State private var viewModel = SubscriptionListViewModel()
    @State private var persistenceErrorMessage: String?

    private var visible: [Subscription] {
        viewModel.visibleSubscriptions(from: subscriptions)
    }

    var body: some View {
        VStack(spacing: 0) {
            controls
            List {
                ForEach(visible) { subscription in
                    SubscriptionListRow(
                        subscription: subscription,
                        baseCurrency: baseCurrency,
                        rates: currencyExchange.rates,
                        compactNumbers: compactNumbers,
                        roundingEnabled: roundingEnabled,
                        onEdit: { onEdit(subscription) },
                        onToggleArchive: {
                            subscription.isActive.toggle()
                            subscription.updatedAt = Date()
                            saveListChange()
                        },
                        onDelete: { onDelete(subscription) }
                    )
                        .contextMenu {
                            Button(L10n.text("edit", language: appLanguage)) { onEdit(subscription) }
                            Button(subscription.isActive ? L10n.text("archive", language: appLanguage) : L10n.text("activate", language: appLanguage)) {
                                subscription.isActive.toggle()
                                subscription.updatedAt = Date()
                                saveListChange()
                            }
                            Divider()
                            Button(L10n.text("delete", language: appLanguage), role: .destructive) { onDelete(subscription) }
                        }
                        .onTapGesture(count: 2) {
                            onEdit(subscription)
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                .onDelete { offsets in
                    offsets.map { visible[$0] }.forEach(onDelete)
                }
            }
            .scrollContentBackground(isSoftNeumorphic ? .hidden : .automatic)
        }
        .navigationTitle(L10n.text("subscriptions", language: appLanguage))
        .background {
            if isSoftNeumorphic {
                Rectangle()
                    .fill(SoftNeumorphicTheme.pageBackground)
                    .ignoresSafeArea()
            }
        }
        .searchable(text: $viewModel.searchText)
        .animation(.snappy(duration: 0.25), value: visible.map(\.id))
        .alert(
            L10n.text("persistenceErrorTitle", language: appLanguage),
            isPresented: Binding(
                get: { persistenceErrorMessage != nil },
                set: { if !$0 { persistenceErrorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {
                persistenceErrorMessage = nil
            }
        } message: {
            Text(persistenceErrorMessage ?? "")
        }
        .toolbar {
            ToolbarItem {
                Button(action: onAdd) {
                    Text("➕")
                }
                .help(L10n.text("addSubscription", language: appLanguage))
            }
        }
    }

    private var controls: some View {
        HStack {
            Picker(L10n.text("filter", language: appLanguage), selection: $viewModel.filter) {
                ForEach(SubscriptionFilter.allCases) { filter in
                    Text(filter.localizedTitle(language: appLanguage)).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 280)

            Picker(L10n.text("sort", language: appLanguage), selection: $viewModel.sort) {
                ForEach(SubscriptionSort.allCases) { sort in
                    Text(sort.localizedTitle(language: appLanguage)).tag(sort)
                }
            }
            .frame(width: 160)

            Spacer()
        }
        .padding()
        .background {
            if isSoftNeumorphic {
                SoftNeumorphicTheme.background
                    .ignoresSafeArea()
            } else {
                Color(nsColor: .windowBackgroundColor)
            }
        }
    }

    private func saveListChange() {
        do {
            try modelContext.save()
        } catch {
            persistenceErrorMessage = L10n.text("saveFailedMessage", language: appLanguage)
        }
    }
}

private struct SubscriptionListRow: View {
    @Environment(\.isSoftNeumorphicTheme) private var isSoftNeumorphic
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.system.rawValue

    let subscription: Subscription
    let baseCurrency: String
    let rates: CurrencyRates
    let compactNumbers: Bool
    let roundingEnabled: Bool
    let onEdit: () -> Void
    let onToggleArchive: () -> Void
    let onDelete: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 14) {
            BrandIcon(
                name: subscription.name,
                iconName: subscription.iconName,
                colorHex: subscription.category?.colorHex ?? "#007AFF",
                size: 42,
            )

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(subscription.name)
                        .font(.headline)
                    if !subscription.isActive {
                        Text(L10n.text("archived", language: appLanguage))
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(.quaternary, in: Capsule())
                    }
                }
                Text("\(subscription.billingPeriod.localizedTitle(language: appLanguage)) · \(L10n.text("next", language: appLanguage)) \(L10n.shortDate(subscription.billableNextPaymentDate(), language: appLanguage))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(MoneyFormatter.string(
                    rates.convert(subscription.amount, from: subscription.currency, to: baseCurrency),
                    currency: baseCurrency,
                    compact: compactNumbers,
                    rounded: roundingEnabled
                ))
                    .font(.headline)
                Text(subscription.paymentMethod.map { L10n.paymentMethodName($0.name, language: appLanguage) } ?? L10n.text("paymentMethodMissing", language: appLanguage))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 6) {
                Button(action: onEdit) {
                    Text("✏️")
                }
                .help(L10n.text("edit", language: appLanguage))

                Button(action: onToggleArchive) {
                    Text(subscription.isActive ? "🗄️" : "↩️")
                }
                .help(subscription.isActive ? L10n.text("archive", language: appLanguage) : L10n.text("activate", language: appLanguage))

                Button(role: .destructive, action: onDelete) {
                    Text("🗑️")
                }
                .help(L10n.text("delete", language: appLanguage))
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
            .opacity(isHovering ? 1 : 0.45)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, isSoftNeumorphic ? 10 : 0)
        .subPulseRaisedSurface(isSoft: isSoftNeumorphic, cornerRadius: 18, fallback: AnyShapeStyle(Color.clear))
        .contentShape(Rectangle())
        .onHover { isHovering = $0 }
        .scaleEffect(isSoftNeumorphic && isHovering ? 0.996 : (isHovering ? 1.004 : 1))
        .animation(.snappy(duration: 0.18), value: isHovering)
    }
}
