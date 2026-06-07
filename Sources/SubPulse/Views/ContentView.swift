import SwiftData
import SwiftUI

private enum ContentSheet: String, Identifiable {
    case picker
    case editor

    var id: String { rawValue }
}

private enum ActiveContentSheet: Identifiable {
    case picker(date: Date?)
    case appStoreImport(date: Date?)
    case editor(id: String, draft: SubscriptionDraft?)

    var id: String {
        switch self {
        case .picker(let date):
            "picker-\(date?.timeIntervalSince1970 ?? 0)"
        case .appStoreImport(let date):
            "appstore-import-\(date?.timeIntervalSince1970 ?? 0)"
        case .editor(let id, _):
            "editor-\(id)"
        }
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Subscription.nextPaymentDate) private var subscriptions: [Subscription]
    @Query(sort: \Category.name) private var categories: [Category]
    @Query(sort: \PaymentMethod.name) private var paymentMethods: [PaymentMethod]

    @AppStorage("appearance") private var appearance = AppAppearance.softNeumorphic.rawValue
    @AppStorage("accent") private var accent = AppAccent.pulseBlue.rawValue
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.system.rawValue
    @AppStorage("firstReminder") private var firstReminder = 1
    @AppStorage("secondReminder") private var secondReminder = 3
    @SceneStorage("selectedDestination") private var selectedDestinationRaw = AppDestination.dashboard.rawValue
    @State private var activeSheet: ActiveContentSheet?
    @State private var editingSubscription: Subscription?
    @State private var persistenceErrorMessage: String?
    @StateObject private var currencyExchange = CurrencyExchangeService.shared

    private var reminderSignature: String {
        subscriptions
            .map {
                [
                    $0.id.uuidString,
                    $0.name,
                    String($0.amount),
                    $0.currency,
                    $0.billingPeriodRaw,
                    String($0.nextPaymentDate.timeIntervalSince1970),
                    String($0.isActive),
                    String($0.updatedAt.timeIntervalSince1970)
                ].joined(separator: "|")
            }
            .joined(separator: ";")
    }

    private var selectedDestination: Binding<AppDestination?> {
        Binding {
            let destination = AppDestination(rawValue: selectedDestinationRaw)
            return destination == .calendar ? .dashboard : destination
        } set: { value in
            selectedDestinationRaw = value?.rawValue ?? AppDestination.dashboard.rawValue
        }
    }

    private var selectedAppearance: AppAppearance {
        AppAppearance(rawValue: appearance) ?? .softNeumorphic
    }

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: selectedDestination)
                .navigationSplitViewColumnWidth(min: 210, ideal: 224, max: 250)
        } detail: {
            switch selectedDestination.wrappedValue ?? .dashboard {
            case .dashboard, .calendar:
                DashboardView(
                    subscriptions: subscriptions,
                    onAdd: { date in activeSheet = .picker(date: date) },
                    onShowAnalytics: { selectedDestinationRaw = AppDestination.analytics.rawValue },
                    onShowSettings: { selectedDestinationRaw = AppDestination.settings.rawValue }
                )
            case .subscriptions:
                SubscriptionListView(
                    subscriptions: subscriptions,
                    onAdd: { activeSheet = .picker(date: nil) },
                    onEdit: { subscription in
                        editingSubscription = subscription
                        activeSheet = .editor(id: subscription.id.uuidString, draft: nil)
                    },
                    onDelete: delete
                )
            case .analytics:
                AnalyticsView(subscriptions: subscriptions, categories: categories)
            case .settings:
                SettingsView(
                    subscriptions: subscriptions,
                    categories: categories,
                    paymentMethods: paymentMethods
                )
            }
        }
        .environmentObject(currencyExchange)
        .environment(\.isSoftNeumorphicTheme, selectedAppearance.isSoftNeumorphic)
        .tint(selectedAppearance.isSoftNeumorphic ? SoftNeumorphicTheme.accent : (AppAccent(rawValue: accent) ?? .pulseBlue).color)
        .preferredColorScheme(selectedAppearance.colorScheme)
        .environment(\.locale, (AppLanguage(rawValue: appLanguage) ?? .system).locale)
        .background {
            if selectedAppearance.isSoftNeumorphic {
                Rectangle()
                    .fill(SoftNeumorphicTheme.pageBackground)
                    .ignoresSafeArea()
            }
        }
        .animation(.snappy(duration: 0.28), value: selectedDestinationRaw)
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .picker(let selectedDate):
                SubscriptionPickerView(
                    categories: categories,
                    paymentMethods: paymentMethods,
                    onAppStoreImport: {
                        activeSheet = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                            activeSheet = .appStoreImport(date: selectedDate)
                        }
                    },
                    onSelect: { draft in
                        var datedDraft = draft
                        if let selectedDate {
                            datedDraft.nextPaymentDate = Calendar.current.startOfDay(for: selectedDate)
                        }
                        editingSubscription = nil
                        activeSheet = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                            activeSheet = .editor(id: "new-\(datedDraft.name)-\(datedDraft.amount)-\(datedDraft.nextPaymentDate.timeIntervalSince1970)", draft: datedDraft)
                        }
                    },
                    onCancel: {
                        activeSheet = nil
                    }
                )
                .environment(\.isSoftNeumorphicTheme, selectedAppearance.isSoftNeumorphic)
                .preferredColorScheme(selectedAppearance.colorScheme)
            case .appStoreImport(let selectedDate):
                AppStoreImportView(
                    categories: categories,
                    paymentMethods: paymentMethods,
                    existingSubscriptionNames: Set(subscriptions.map { SubscriptionNameNormalizer.normalized($0.name) }),
                    defaultDate: selectedDate,
                    onConfirm: importDrafts,
                    onCancel: {
                        activeSheet = nil
                    }
                )
                .environment(\.isSoftNeumorphicTheme, selectedAppearance.isSoftNeumorphic)
                .preferredColorScheme(selectedAppearance.colorScheme)
            case .editor(_, let draft):
                SubscriptionEditorView(
                    subscription: editingSubscription,
                    categories: categories,
                    paymentMethods: paymentMethods,
                    initialDraft: draft,
                    onSave: save,
                    onCancel: {
                        editingSubscription = nil
                        activeSheet = nil
                    }
                )
                .id(sheet.id)
                .frame(minWidth: 560, minHeight: 680)
                .environment(\.isSoftNeumorphicTheme, selectedAppearance.isSoftNeumorphic)
                .preferredColorScheme(selectedAppearance.colorScheme)
            }
        }
        .onAppear {
            appearance = AppAppearance.normalizedRawValue(appearance)
            SeedService.seedIfNeeded(in: modelContext)
            Task { await rescheduleAllReminders() }
            Task { await currencyExchange.refreshIfNeeded() }
        }
        .onChange(of: reminderSignature) { _, _ in
            Task { await rescheduleAllReminders() }
        }
        .onChange(of: firstReminder) { _, _ in
            Task { await rescheduleAllReminders() }
        }
        .onChange(of: secondReminder) { _, _ in
            Task { await rescheduleAllReminders() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .showSubscriptionEditor)) { _ in
            editingSubscription = nil
            activeSheet = .picker(date: nil)
        }
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
    }

    private func save(_ draft: SubscriptionDraft) {
        var subscriptionToSchedule: Subscription?
        var subscriptionToCancel: Subscription?

        if let editingSubscription {
            editingSubscription.name = draft.name
            editingSubscription.amount = draft.amount
            editingSubscription.currency = draft.currency
            editingSubscription.billingPeriod = draft.billingPeriod
            editingSubscription.nextPaymentDate = draft.nextPaymentDate
            editingSubscription.trialStartDate = draft.trialStartDate
            editingSubscription.trialEndDate = draft.trialEndDate
            editingSubscription.category = draft.category
            editingSubscription.paymentMethod = draft.paymentMethod
            editingSubscription.iconName = draft.iconName
            editingSubscription.notes = draft.notes
            editingSubscription.isActive = draft.isActive
            editingSubscription.updatedAt = Date()
            if draft.isActive {
                subscriptionToSchedule = editingSubscription
            } else {
                subscriptionToCancel = editingSubscription
            }
        } else {
            let subscription = Subscription(
                name: draft.name,
                amount: draft.amount,
                currency: draft.currency,
                billingPeriod: draft.billingPeriod,
                nextPaymentDate: draft.nextPaymentDate,
                trialStartDate: draft.trialStartDate,
                trialEndDate: draft.trialEndDate,
                category: draft.category,
                paymentMethod: draft.paymentMethod,
                iconName: draft.iconName,
                notes: draft.notes,
                isActive: draft.isActive
            )
            modelContext.insert(subscription)
            if subscription.isActive {
                subscriptionToSchedule = subscription
            }
        }

        do {
            try modelContext.save()
        } catch {
            persistenceErrorMessage = L10n.text("saveFailedMessage", language: appLanguage)
            return
        }

        if let subscriptionToCancel {
            NotificationService.shared.cancelReminders(for: subscriptionToCancel)
        }
        if let subscriptionToSchedule {
            Task { await scheduleReminders(for: subscriptionToSchedule) }
        }
        editingSubscription = nil
        activeSheet = nil
    }

    private func importDrafts(_ drafts: [SubscriptionDraft]) {
        var existingNames = Set(subscriptions.map { SubscriptionNameNormalizer.normalized($0.name) })
        var importedSubscriptions: [Subscription] = []

        for draft in drafts where draft.amount > 0 && !draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let normalizedName = SubscriptionNameNormalizer.normalized(draft.name)
            guard !existingNames.contains(normalizedName) else { continue }
            existingNames.insert(normalizedName)

            let subscription = Subscription(
                name: draft.name,
                amount: draft.amount,
                currency: draft.currency,
                billingPeriod: draft.billingPeriod,
                nextPaymentDate: draft.nextPaymentDate,
                trialStartDate: draft.trialStartDate,
                trialEndDate: draft.trialEndDate,
                category: draft.category,
                paymentMethod: draft.paymentMethod,
                iconName: draft.iconName,
                notes: draft.notes,
                isActive: draft.isActive
            )
            modelContext.insert(subscription)
            importedSubscriptions.append(subscription)
        }

        do {
            try modelContext.save()
        } catch {
            persistenceErrorMessage = L10n.text("importSaveFailedMessage", language: appLanguage)
            return
        }

        for subscription in importedSubscriptions where subscription.isActive {
            Task { await scheduleReminders(for: subscription) }
        }
        activeSheet = nil
    }

    private func delete(_ subscription: Subscription) {
        NotificationService.shared.cancelReminders(for: subscription)
        modelContext.delete(subscription)
        do {
            try modelContext.save()
        } catch {
            persistenceErrorMessage = L10n.text("deleteFailedMessage", language: appLanguage)
        }
    }

    private func scheduleReminders(for subscription: Subscription) async {
        await NotificationService.shared.scheduleReminders(
            for: subscription,
            firstDaysBefore: firstReminder,
            secondDaysBefore: secondReminder,
            language: appLanguage
        )
    }

    private func rescheduleAllReminders() async {
        await NotificationService.shared.scheduleReminders(
            for: subscriptions,
            firstDaysBefore: firstReminder,
            secondDaysBefore: secondReminder,
            language: appLanguage
        )
    }
}
