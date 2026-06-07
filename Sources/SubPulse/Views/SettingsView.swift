import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.isSoftNeumorphicTheme) private var isSoftNeumorphic
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.system.rawValue
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var currencyExchange: CurrencyExchangeService
    @StateObject private var reminderService = ReminderService.shared
    @State private var showResetConfirmation = false
    @State private var showRestoreConfirmation = false
    @State private var resetStatus: String?
    @State private var backupStatus: String?
    @State private var managementStatus: String?
    @State private var showCategoryEditor = false
    @State private var showPaymentMethodEditor = false

    let subscriptions: [Subscription]
    let categories: [Category]
    let paymentMethods: [PaymentMethod]

    @AppStorage("baseCurrency") private var baseCurrency = "USD"
    @AppStorage("roundingEnabled") private var roundingEnabled = false
    @AppStorage("compactNumbers") private var compactNumbers = false
    @AppStorage("firstReminder") private var firstReminder = 1
    @AppStorage("secondReminder") private var secondReminder = 3
    @AppStorage("appearance") private var appearance = AppAppearance.softNeumorphic.rawValue
    @AppStorage("accent") private var accent = AppAccent.pulseBlue.rawValue

    private let settingsColumns = [
        GridItem(.flexible(minimum: 320), spacing: 18, alignment: .top),
        GridItem(.flexible(minimum: 320), spacing: 18, alignment: .top)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: settingsColumns, alignment: .leading, spacing: 22) {
                dataCard
                preferencesCard
                remindersCard
                appearanceCard
                categoriesCard
                paymentMethodsCard
                aboutCard
                dangerCard
            }
            .frame(maxWidth: 1040)
            .frame(maxWidth: .infinity)
            .padding(24)
        }
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
        .navigationTitle(L10n.text("settings", language: appLanguage))
        .confirmationDialog(
            L10n.text("resetAllTitle", language: appLanguage),
            isPresented: $showResetConfirmation,
            titleVisibility: .visible
        ) {
            Button(L10n.text("resetAllConfirm", language: appLanguage), role: .destructive) {
                Task { await resetAll() }
            }
            Button(L10n.text("cancel", language: appLanguage), role: .cancel) {}
        } message: {
            Text(L10n.text("resetAllMessage", language: appLanguage))
        }
        .confirmationDialog(
            L10n.text("restoreBackupTitle", language: appLanguage),
            isPresented: $showRestoreConfirmation,
            titleVisibility: .visible
        ) {
            Button(L10n.text("restoreBackupConfirm", language: appLanguage), role: .destructive) {
                restoreBackup()
            }
            Button(L10n.text("cancel", language: appLanguage), role: .cancel) {}
        } message: {
            Text(L10n.text("restoreBackupMessage", language: appLanguage))
        }
        .sheet(isPresented: $showCategoryEditor) {
            CategoryEditorSheet(language: appLanguage, onSave: createCategory)
                .environment(\.isSoftNeumorphicTheme, isSoftNeumorphic)
        }
        .sheet(isPresented: $showPaymentMethodEditor) {
            PaymentMethodEditorSheet(language: appLanguage, onSave: createPaymentMethod)
                .environment(\.isSoftNeumorphicTheme, isSoftNeumorphic)
        }
        .animation(.snappy, value: appearance)
        .animation(.snappy, value: accent)
        .animation(.snappy, value: appLanguage)
        .onAppear {
            appearance = AppAppearance.normalizedRawValue(appearance)
        }
    }

    private var dataCard: some View {
        SettingsSectionCard(title: L10n.text("dataMode", language: appLanguage)) {
            LabeledContent(L10n.text("data", language: appLanguage), value: L10n.text("localPlaceholder", language: appLanguage))
            SettingsDivider()
            LabeledContent(L10n.text("product", language: appLanguage), value: L10n.text("fullyFree", language: appLanguage))
            SettingsDivider()

            HStack {
                Button {
                    exportBackup()
                } label: {
                    Label(L10n.text("exportBackup", language: appLanguage), systemImage: "square.and.arrow.up")
                }

                Button {
                    showRestoreConfirmation = true
                } label: {
                    Label(L10n.text("restoreBackup", language: appLanguage), systemImage: "arrow.down.doc")
                }
            }

            if let backupStatus {
                Text(backupStatus)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var preferencesCard: some View {
        SettingsSectionCard(title: L10n.text("preferences", language: appLanguage)) {
            Picker(L10n.text("language", language: appLanguage), selection: $appLanguage) {
                ForEach(AppLanguage.allCases) { language in
                    Text(language.localizedTitle(language: appLanguage)).tag(language.rawValue)
                }
            }
            SettingsDivider()

            Picker(L10n.text("baseCurrency", language: appLanguage), selection: $baseCurrency) {
                ForEach(CurrencyCatalog.all) { currency in
                    CurrencyPickerLabel(currency: currency, language: appLanguage)
                        .tag(currency.code)
                }
            }
            SettingsDivider()

            CurrencyRatePanel(
                currencyCode: baseCurrency,
                rates: currencyExchange.rates,
                language: appLanguage,
                isRefreshing: currencyExchange.isRefreshing,
                updatedText: exchangeRateStatus,
                onRefresh: {
                    Task { await currencyExchange.refresh() }
                }
            )
            SettingsDivider()

            Toggle(L10n.text("rounding", language: appLanguage), isOn: $roundingEnabled)
            SettingsDivider()
            Toggle(L10n.text("compactNumbers", language: appLanguage), isOn: $compactNumbers)
        }
    }

    private var remindersCard: some View {
        SettingsSectionCard(title: L10n.text("reminders", language: appLanguage)) {
            ReminderTimingRow(
                emoji: "⏰",
                title: L10n.text("firstReminderTitle", language: appLanguage),
                subtitle: String(format: L10n.text("daysBeforeFormat", language: appLanguage), firstReminder),
                value: $firstReminder,
                range: 0...14
            )
            SettingsDivider()
            ReminderTimingRow(
                emoji: "🔔",
                title: L10n.text("secondReminderTitle", language: appLanguage),
                subtitle: String(format: L10n.text("daysBeforeFormat", language: appLanguage), secondReminder),
                value: $secondReminder,
                range: 0...30
            )
            SettingsDivider()

            VStack(spacing: 10) {
                SettingsActionButton(title: L10n.text("sendTestNotification", language: appLanguage), systemImage: "bell.badge") {
                    Task { await NotificationService.shared.sendTestNotification(language: appLanguage) }
                }

                SettingsActionButton(
                    title: L10n.text("syncRemindersApp", language: appLanguage),
                    systemImage: "checklist",
                    isDisabled: reminderService.isSyncing
                ) {
                    Task {
                        await reminderService.sync(
                            subscriptions: subscriptions,
                            firstDaysBefore: firstReminder,
                            secondDaysBefore: secondReminder,
                            language: appLanguage
                        )
                    }
                }

                SettingsActionButton(title: L10n.text("openRemindersApp", language: appLanguage), systemImage: "calendar.badge.clock") {
                    reminderService.openRemindersApp()
                }
            }

            if let status = reminderService.lastSyncStatus {
                Text(status)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var appearanceCard: some View {
        SettingsSectionCard(title: L10n.text("appearance", language: appLanguage)) {
            Picker(L10n.text("mode", language: appLanguage), selection: $appearance) {
                ForEach(AppAppearance.allCases) { mode in
                    Text(mode.localizedTitle(language: appLanguage)).tag(mode.rawValue)
                }
            }
            SettingsDivider()

            if isSoftNeumorphic {
                SoftNeumorphicThemePreview(language: appLanguage)
                SettingsDivider()
            }

            Picker(L10n.text("accent", language: appLanguage), selection: $accent) {
                ForEach(AppAccent.allCases) { accent in
                    HStack {
                        Circle()
                            .fill(accent.color)
                            .frame(width: 10, height: 10)
                        Text(accent.localizedTitle(language: appLanguage))
                    }
                    .tag(accent.rawValue)
                }
            }
            SettingsDivider()
            LabeledContent(L10n.text("haptic", language: appLanguage), value: L10n.text("placeholder", language: appLanguage))
        }
    }

    private var categoriesCard: some View {
        SettingsSectionCard(title: L10n.text("categories", language: appLanguage)) {
            HStack {
                Text(String(format: L10n.text("itemsCountFormat", language: appLanguage), categories.count))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    showCategoryEditor = true
                } label: {
                    Label(L10n.text("addCategory", language: appLanguage), systemImage: "plus")
                }
            }
            SettingsDivider()

            ForEach(Array(categories.enumerated()), id: \.element.id) { index, category in
                HStack {
                    Text(EmojiIcon.emoji(for: category.iconName))
                    Text(L10n.categoryName(category.name, language: appLanguage))
                    Spacer()
                }
                if index < categories.count - 1 {
                    SettingsDivider()
                }
            }

            if let managementStatus {
                SettingsDivider()
                Text(managementStatus)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var paymentMethodsCard: some View {
        SettingsSectionCard(title: L10n.text("paymentMethods", language: appLanguage)) {
            HStack {
                Text(String(format: L10n.text("itemsCountFormat", language: appLanguage), orderedPaymentMethods.count))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    showPaymentMethodEditor = true
                } label: {
                    Label(L10n.text("addPaymentMethod", language: appLanguage), systemImage: "plus")
                }
            }
            SettingsDivider()

            ForEach(Array(orderedPaymentMethods.enumerated()), id: \.element.id) { index, method in
                PaymentMethodSettingsRow(method: method, language: appLanguage)
                if index < orderedPaymentMethods.count - 1 {
                    SettingsDivider()
                }
            }
        }
    }

    private var aboutCard: some View {
        SettingsSectionCard(title: L10n.text("about", language: appLanguage)) {
            LabeledContent(L10n.text("product", language: appLanguage), value: "SubPulse")
            SettingsDivider()
            LabeledContent(L10n.text("version", language: appLanguage), value: BundleInfo.displayVersion)
            SettingsDivider()
            Text(L10n.text("aboutText", language: appLanguage))
                .foregroundStyle(.secondary)
        }
    }

    private var dangerCard: some View {
        SettingsSectionCard(title: L10n.text("dangerZone", language: appLanguage)) {
            Button(role: .destructive) {
                showResetConfirmation = true
            } label: {
                Label(L10n.text("resetAll", language: appLanguage), systemImage: "arrow.counterclockwise.circle")
            }
            SettingsDivider()

            Text(L10n.text("resetAllHint", language: appLanguage))
                .font(.caption)
                .foregroundStyle(.secondary)

            if let resetStatus {
                Text(resetStatus)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var exchangeRateStatus: String {
        guard let updatedAt = currencyExchange.rates.updatedAt else {
            return L10n.text("exchangeFallback", language: appLanguage)
        }
        return "\(L10n.text("updated", language: appLanguage)) \(L10n.shortDate(updatedAt, language: appLanguage))"
    }

    private var orderedPaymentMethods: [PaymentMethod] {
        paymentMethods.sorted { lhs, rhs in
            paymentMethodOrder(lhs.name) < paymentMethodOrder(rhs.name)
        }
    }

    private func paymentMethodOrder(_ name: String) -> Int {
        ["Apple Pay", "Google Pay", "Дебетовая карта", "Debit Card", "Кредитная карта", "Credit Card"].firstIndex(of: name) ?? Int.max
    }

    @MainActor
    private func exportBackup() {
        backupStatus = DataBackupService.exportBackup(
            subscriptions: subscriptions,
            categories: categories,
            paymentMethods: paymentMethods,
            language: appLanguage
        )
    }

    @MainActor
    private func restoreBackup() {
        guard let result = DataBackupService.restoreBackup(
            in: modelContext,
            existingSubscriptions: subscriptions,
            existingCategories: categories,
            existingPaymentMethods: paymentMethods,
            language: appLanguage
        ) else {
            return
        }

        backupStatus = result.message
        Task {
            await NotificationService.shared.scheduleReminders(
                for: result.subscriptions,
                firstDaysBefore: firstReminder,
                secondDaysBefore: secondReminder,
                language: appLanguage
            )
        }
    }

    @MainActor
    private func createCategory(_ draft: CategoryDraft) {
        let trimmedName = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        modelContext.insert(Category(name: trimmedName, colorHex: draft.colorHex, iconName: draft.iconName))
        do {
            try modelContext.save()
            managementStatus = L10n.text("categoryAdded", language: appLanguage)
        } catch {
            managementStatus = L10n.text("saveFailedMessage", language: appLanguage)
        }
    }

    @MainActor
    private func createPaymentMethod(_ draft: PaymentMethodDraft) {
        let trimmedName = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        guard !paymentMethods.contains(where: { $0.name.localizedCaseInsensitiveCompare(trimmedName) == .orderedSame }) else {
            managementStatus = L10n.text("paymentMethodAlreadyExists", language: appLanguage)
            return
        }

        let last4 = draft.last4.trimmingCharacters(in: .whitespacesAndNewlines)
        modelContext.insert(PaymentMethod(
            name: trimmedName,
            type: draft.type.storageType,
            last4: last4.isEmpty ? nil : last4,
            colorHex: draft.colorHex
        ))
        do {
            try modelContext.save()
            managementStatus = L10n.text("paymentMethodAdded", language: appLanguage)
        } catch {
            managementStatus = L10n.text("saveFailedMessage", language: appLanguage)
        }
    }

    @MainActor
    private func resetAll() async {
        let languageBeforeReset = appLanguage

        await reminderService.deleteSubPulseReminders(language: languageBeforeReset)

        for subscription in subscriptions {
            NotificationService.shared.cancelReminders(for: subscription)
            modelContext.delete(subscription)
        }

        for category in categories {
            modelContext.delete(category)
        }

        for method in paymentMethods {
            modelContext.delete(method)
        }

        do {
            try modelContext.save()
        } catch {
            resetStatus = L10n.text("resetAllFailed", language: languageBeforeReset)
            return
        }

        resetPreferences()
        SeedService.markAllDataResetCompleted()
        resetStatus = L10n.text("resetAllDone", language: appLanguage)
    }

    private func resetPreferences() {
        appLanguage = AppLanguage.system.rawValue
        baseCurrency = "USD"
        roundingEnabled = false
        compactNumbers = false
        firstReminder = 1
        secondReminder = 3
        appearance = AppAppearance.softNeumorphic.rawValue
        accent = AppAccent.pulseBlue.rawValue
        UserDefaults.standard.removeObject(forKey: "currencyRates.cbr.cached")
    }
}

private struct SoftNeumorphicThemePreview: View {
    let language: String

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.text("softNeumorphicPreviewTitle", language: language))
                    .font(.headline)
                    .foregroundStyle(SoftNeumorphicTheme.text)
                Text(L10n.text("softNeumorphicPreviewSubtitle", language: language))
                    .font(.caption)
                    .foregroundStyle(SoftNeumorphicTheme.mutedText)
            }
            Spacer()
            HStack(spacing: 8) {
                Circle()
                    .fill(SoftNeumorphicTheme.accent)
                    .frame(width: 28, height: 28)
                    .softNeumorphicRaisedShadow(isEnabled: true)
                RoundedRectangle(cornerRadius: 999)
                    .fill(SoftNeumorphicTheme.surface)
                    .frame(width: 58, height: 26)
                    .softNeumorphicInsetShadow(isEnabled: true)
            }
        }
        .padding(16)
        .background {
            SoftNeumorphicRoundedSurface(depth: .raisedSoft, cornerRadius: 22)
        }
    }
}

private struct CurrencyPickerLabel: View {
    let currency: CurrencyInfo
    let language: String

    var body: some View {
        Text("\(currency.flag) \(currency.code)")
    }
}

private struct CurrencyRatePanel: View {
    @Environment(\.isSoftNeumorphicTheme) private var isSoftNeumorphic

    let currencyCode: String
    let rates: CurrencyRates
    let language: String
    let isRefreshing: Bool
    let updatedText: String
    let onRefresh: () -> Void

    var body: some View {
        let info = CurrencyCatalog.info(for: currencyCode)

        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Text(info.flag)
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(info.code) · \(CurrencyCatalog.localizedCountry(for: info.code, language: language))")
                        .font(.headline)
                    Text(CurrencyCatalog.localizedCentralBank(for: info.code, language: language))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(L10n.text("refresh", language: language), action: onRefresh)
                    .disabled(isRefreshing)
            }

            Text(CurrencyCatalog.cbrRateText(for: info.code, rates: rates, language: language))
                .font(.callout.weight(.semibold))
            Text(updatedText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .subPulseInsetSurface(
            isSoft: isSoftNeumorphic,
            cornerRadius: 18,
            fallback: AnyShapeStyle(Color(nsColor: .controlBackgroundColor))
        )
    }
}

private struct ReminderTimingRow: View {
    @Environment(\.isSoftNeumorphicTheme) private var isSoftNeumorphic

    let emoji: String
    let title: String
    let subtitle: String
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        HStack(spacing: 12) {
            Text(emoji)
                .font(.title2)
                .frame(width: 44, height: 44)
                .subPulseRaisedSurface(
                    isSoft: isSoftNeumorphic,
                    cornerRadius: 16,
                    fallback: AnyShapeStyle(Color(nsColor: .controlBackgroundColor))
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Stepper(value: $value, in: range) {
                Text("\(value)")
                    .font(.title3.bold())
                    .monospacedDigit()
                    .frame(minWidth: 28)
            }
        }
        .padding(10)
        .subPulseInsetSurface(
            isSoft: isSoftNeumorphic,
            cornerRadius: 18,
            fallback: AnyShapeStyle(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        )
    }
}

private struct PaymentMethodSettingsRow: View {
    let method: PaymentMethod
    let language: String

    var body: some View {
        HStack(spacing: 10) {
            Text(PaymentMethodVisual.emoji(for: method))
                .font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.paymentMethodName(method.name, language: language))
                    .font(.headline)
                Text(method.last4.map { "\(PaymentMethodType.localizedTitle(for: method.type, language: language)) •••• \($0)" } ?? PaymentMethodType.localizedTitle(for: method.type, language: language))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}

private struct SettingsActionButton: View {
    @Environment(\.isSoftNeumorphicTheme) private var isSoftNeumorphic

    let title: String
    let systemImage: String
    var isDisabled = false
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 18)
                Text(title)
                    .font(.callout.weight(.semibold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 8)
            }
            .foregroundStyle(isDisabled ? .secondary : Color.accentColor)
            .padding(.horizontal, 13)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                if isSoftNeumorphic {
                    SoftNeumorphicRoundedSurface(
                        depth: isHovering ? .pressed : .raisedSoft,
                        cornerRadius: 16,
                        fill: AnyShapeStyle(isHovering ? SoftNeumorphicTheme.surfaceInset : SoftNeumorphicTheme.surface)
                    )
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(nsColor: .controlBackgroundColor))
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.55 : 1)
        .scaleEffect(isSoftNeumorphic && isHovering ? 0.992 : 1)
        .onHover { hovering in
            guard !isDisabled else { return }
            isHovering = hovering
        }
        .animation(.smooth(duration: 0.18), value: isHovering)
    }
}

private struct CategoryDraft {
    var name = ""
    var iconName = "✨"
    var colorHex = "#6B7FD7"
}

private struct CategorySuggestion: Identifiable {
    let id = UUID()
    let name: String
    let emoji: String
    let colorHex: String
}

private let popularCategorySuggestions = [
    CategorySuggestion(name: "Streaming", emoji: "🎬", colorHex: "#FF2D55"),
    CategorySuggestion(name: "Music", emoji: "🎵", colorHex: "#1DB954"),
    CategorySuggestion(name: "AI Tools", emoji: "✨", colorHex: "#AF52DE"),
    CategorySuggestion(name: "Cloud Storage", emoji: "☁️", colorHex: "#4F8EF7"),
    CategorySuggestion(name: "Productivity", emoji: "✅", colorHex: "#34C759"),
    CategorySuggestion(name: "Finance", emoji: "💳", colorHex: "#00C7BE"),
    CategorySuggestion(name: "Education", emoji: "📚", colorHex: "#64D2FF"),
    CategorySuggestion(name: "Security", emoji: "🛡️", colorHex: "#8E8E93"),
    CategorySuggestion(name: "Family", emoji: "👨‍👩‍👧", colorHex: "#FF9F0A"),
    CategorySuggestion(name: "Utilities", emoji: "🧰", colorHex: "#BF5AF2")
]

private struct CategoryEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isSoftNeumorphicTheme) private var isSoftNeumorphic

    let language: String
    let onSave: (CategoryDraft) -> Void

    @State private var draft = CategoryDraft()

    private let emojiChoices = ["✨", "☁️", "🎬", "🎵", "✅", "🧩", "🎮", "📰", "🏋️", "💳", "📚", "🛡️", "🧰", "👨‍👩‍👧", "🚗", "🏠", "🍿", "🧠", "💼", "🌍", "📦", "🛒", "☕️", "🎨"]
    private let colorChoices = ["#6B7FD7", "#34C759", "#FF2D55", "#FF9500", "#AF52DE", "#4F8EF7", "#00C7BE", "#8E8E93"]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            sheetHeader(title: L10n.text("addCategory", language: language))

            TextField(L10n.text("categoryName", language: language), text: $draft.name)
                .textFieldStyle(.plain)
                .padding(12)
                .subPulseInsetSurface(isSoft: isSoftNeumorphic, cornerRadius: 16)

            VStack(alignment: .leading, spacing: 10) {
                Text(L10n.text("popularCategories", language: language))
                    .font(.headline)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                    ForEach(popularCategorySuggestions) { suggestion in
                        Button {
                            draft.name = suggestion.name
                            draft.iconName = suggestion.emoji
                            draft.colorHex = suggestion.colorHex
                        } label: {
                            HStack {
                                Text(suggestion.emoji)
                                Text(L10n.categoryName(suggestion.name, language: language))
                                    .lineLimit(1)
                                Spacer()
                            }
                            .padding(9)
                            .frame(maxWidth: .infinity)
                            .subPulseRaisedSurface(isSoft: isSoftNeumorphic, cornerRadius: 14)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text(L10n.text("chooseEmoji", language: language))
                    .font(.headline)
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(38), spacing: 8), count: 8), spacing: 8) {
                    ForEach(emojiChoices, id: \.self) { emoji in
                        Button {
                            draft.iconName = emoji
                        } label: {
                            Text(emoji)
                                .font(.title3)
                                .frame(width: 38, height: 38)
                                .subPulseRaisedSurface(
                                    isSoft: isSoftNeumorphic,
                                    cornerRadius: 14,
                                    fallback: AnyShapeStyle(Color(nsColor: .controlBackgroundColor))
                                )
                                .overlay {
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(draft.iconName == emoji ? Color.accentColor : .clear, lineWidth: 2)
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            HStack(spacing: 10) {
                ForEach(colorChoices, id: \.self) { colorHex in
                    Button {
                        draft.colorHex = colorHex
                    } label: {
                        Circle()
                            .fill(Color(hex: colorHex))
                            .frame(width: 28, height: 28)
                            .overlay {
                                Circle()
                                    .stroke(draft.colorHex == colorHex ? Color.primary : .clear, lineWidth: 2)
                            }
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack {
                Spacer()
                Button(L10n.text("cancel", language: language)) {
                    dismiss()
                }
                Button(L10n.text("save", language: language)) {
                    onSave(draft)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(22)
        .frame(width: 520)
        .background {
            if isSoftNeumorphic {
                Rectangle()
                    .fill(SoftNeumorphicTheme.pageBackground)
                    .ignoresSafeArea()
            }
        }
    }

    private func sheetHeader(title: String) -> some View {
        HStack {
            Text(title)
                .font(.title.bold())
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
        }
    }
}

struct PaymentMethodDraft {
    var name = ""
    var type: PaymentMethodType = .custom
    var last4 = ""
    var colorHex = "#6B7FD7"
}

enum PaymentMethodType: String, CaseIterable, Identifiable {
    case custom
    case wallet
    case debit
    case credit
    case bank
    case cash

    var id: String { rawValue }

    var storageType: String {
        switch self {
        case .custom: "Custom"
        case .wallet: "Wallet"
        case .debit: "Debit"
        case .credit: "Credit"
        case .bank: "Bank"
        case .cash: "Cash"
        }
    }

    var emoji: String {
        switch self {
        case .custom: "✨"
        case .wallet: "👛"
        case .debit: "💳"
        case .credit: "💎"
        case .bank: "🏦"
        case .cash: "💵"
        }
    }

    func localizedTitle(language: String) -> String {
        L10n.text("paymentType\(storageType)", language: language)
    }

    static func localizedTitle(for storageType: String, language: String) -> String {
        let matched = allCases.first { $0.storageType.localizedCaseInsensitiveCompare(storageType) == .orderedSame }
        return matched?.localizedTitle(language: language) ?? storageType
    }
}

enum PaymentMethodVisual {
    static func emoji(for method: PaymentMethod) -> String {
        let normalizedName = method.name.lowercased()
        let normalizedType = method.type.lowercased()
        if normalizedName.contains("apple") { return "" }
        if normalizedName.contains("google") { return "G" }
        if normalizedType.contains("credit") || normalizedName.contains("кредит") { return "💎" }
        if normalizedType.contains("debit") || normalizedName.contains("дебет") { return "💳" }
        if normalizedType.contains("wallet") { return "👛" }
        if normalizedType.contains("bank") { return "🏦" }
        if normalizedType.contains("cash") { return "💵" }
        return "✨"
    }
}

struct PaymentMethodEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isSoftNeumorphicTheme) private var isSoftNeumorphic

    let language: String
    let onSave: (PaymentMethodDraft) -> Void

    @State private var draft = PaymentMethodDraft()

    private let colorChoices = ["#6B7FD7", "#34C759", "#FF2D55", "#FF9500", "#AF52DE", "#4F8EF7", "#00C7BE", "#8E8E93"]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text(L10n.text("addPaymentMethod", language: language))
                    .font(.title.bold())
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
            }

            TextField(L10n.text("paymentMethodName", language: language), text: $draft.name)
                .textFieldStyle(.plain)
                .padding(12)
                .subPulseInsetSurface(isSoft: isSoftNeumorphic, cornerRadius: 16)

            HStack(spacing: 12) {
                Text(L10n.text("paymentMethodType", language: language))
                    .font(.headline)
                Spacer()
                Picker("", selection: $draft.type) {
                    ForEach(PaymentMethodType.allCases) { type in
                        Text("\(type.emoji) \(type.localizedTitle(language: language))").tag(type)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .frame(minWidth: 190)
            }
            .padding(12)
            .subPulseInsetSurface(isSoft: isSoftNeumorphic, cornerRadius: 16)

            TextField(L10n.text("last4Optional", language: language), text: $draft.last4)
                .textFieldStyle(.plain)
                .padding(12)
                .subPulseInsetSurface(isSoft: isSoftNeumorphic, cornerRadius: 16)

            VStack(alignment: .leading, spacing: 10) {
                Text(L10n.text("chooseColor", language: language))
                    .font(.headline)
                HStack(spacing: 10) {
                    ForEach(colorChoices, id: \.self) { colorHex in
                        Button {
                            draft.colorHex = colorHex
                        } label: {
                            Circle()
                                .fill(Color(hex: colorHex))
                                .frame(width: 30, height: 30)
                                .padding(8)
                                .subPulseRaisedSurface(isSoft: isSoftNeumorphic, cornerRadius: 16)
                                .overlay {
                                    Circle()
                                        .stroke(draft.colorHex == colorHex ? Color.primary : .clear, lineWidth: 2)
                                        .frame(width: 30, height: 30)
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            HStack {
                Spacer()
                Button(L10n.text("cancel", language: language)) {
                    dismiss()
                }
                Button(L10n.text("save", language: language)) {
                    onSave(draft)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(22)
        .frame(width: 520)
        .background {
            if isSoftNeumorphic {
                Rectangle()
                    .fill(SoftNeumorphicTheme.pageBackground)
                    .ignoresSafeArea()
            }
        }
    }
}

private struct SettingsSectionCard<Content: View>: View {
    @Environment(\.isSoftNeumorphicTheme) private var isSoftNeumorphic

    let title: String
    @ViewBuilder let content: Content

    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
                .padding(.horizontal, 4)

            VStack(alignment: .leading, spacing: 10) {
                content
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                if isSoftNeumorphic {
                    SoftNeumorphicRoundedSurface(
                        depth: isHovering ? .pressed : .raisedSoft,
                        cornerRadius: 22,
                        fill: AnyShapeStyle(isHovering ? SoftNeumorphicTheme.surfaceInset : SoftNeumorphicTheme.surface)
                    )
                } else {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(nsColor: .controlBackgroundColor))
                }
            }
            .scaleEffect(isSoftNeumorphic && isHovering ? 0.996 : 1)
            .onHover { isHovering = $0 }
            .animation(.smooth(duration: 0.18), value: isHovering)
        }
    }
}

private struct SettingsDivider: View {
    @Environment(\.isSoftNeumorphicTheme) private var isSoftNeumorphic

    var body: some View {
        Rectangle()
            .fill(isSoftNeumorphic ? SoftNeumorphicTheme.line : Color.secondary.opacity(0.18))
            .frame(height: 1)
    }
}
