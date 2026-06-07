import SwiftData
import SwiftUI

struct SubscriptionEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.isSoftNeumorphicTheme) private var isSoftNeumorphic
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.system.rawValue

    let subscription: Subscription?
    let categories: [Category]
    let paymentMethods: [PaymentMethod]
    let initialDraft: SubscriptionDraft?
    let onSave: (SubscriptionDraft) -> Void
    let onCancel: () -> Void

    @State private var draft: SubscriptionDraft
    @State private var amountText: String
    @State private var nextPaymentDateText: String
    @State private var trialEnabled: Bool
    @State private var trialStartDate: Date
    @State private var trialEndDate: Date
    @State private var trialStartDateText: String
    @State private var trialEndDateText: String
    @State private var selectedCategoryID: UUID?
    @State private var selectedPaymentMethodID: UUID?
    @State private var locallyCreatedPaymentMethod: PaymentMethod?
    @State private var showPaymentMethodEditor = false
    @State private var paymentMethodStatus: String?

    private var parsedAmount: Double {
        Self.parseAmount(amountText)
    }

    private var parsedDate: Date? {
        Self.parseDate(nextPaymentDateText)
    }

    private var parsedTrialStartDate: Date? {
        Self.parseDate(trialStartDateText)
    }

    private var parsedTrialEndDate: Date? {
        Self.parseDate(trialEndDateText)
    }

    private var trialDateRangeIsValid: Bool {
        guard trialEnabled else { return true }
        guard let start = parsedTrialStartDate, let end = parsedTrialEndDate else { return false }
        return start <= end
    }

    private var canSave: Bool {
        !draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            parsedAmount > 0 &&
            parsedDate != nil &&
            trialDateRangeIsValid
    }

    private var validationMessage: String? {
        var missing: [String] = []
        if draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            missing.append(L10n.text("needName", language: appLanguage))
        }
        if parsedAmount <= 0 {
            missing.append(L10n.text("needAmount", language: appLanguage))
        }
        if parsedDate == nil {
            missing.append(L10n.text("needDate", language: appLanguage))
        }
        if !trialDateRangeIsValid {
            missing.append(L10n.text("needTrialRange", language: appLanguage))
        }

        if !missing.isEmpty {
            return "\(L10n.text("requiredPrefix", language: appLanguage)): \(missing.joined(separator: ", "))."
        }
        return nil
    }

    private var sourceDraft: SubscriptionDraft {
        subscription.map(SubscriptionDraft.init(subscription:)) ?? initialDraft ?? SubscriptionDraft()
    }

    init(
        subscription: Subscription?,
        categories: [Category],
        paymentMethods: [PaymentMethod],
        initialDraft: SubscriptionDraft? = nil,
        onSave: @escaping (SubscriptionDraft) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.subscription = subscription
        self.categories = categories
        self.paymentMethods = paymentMethods
        self.initialDraft = initialDraft
        self.onSave = onSave
        self.onCancel = onCancel
        let sourceDraft = subscription.map(SubscriptionDraft.init(subscription:)) ?? initialDraft ?? SubscriptionDraft()
        let storedLanguage = UserDefaults.standard.string(forKey: "appLanguage") ?? AppLanguage.system.rawValue
        let defaultTrialStart = sourceDraft.trialStartDate ?? sourceDraft.nextPaymentDate
        let defaultTrialEnd = sourceDraft.trialEndDate ?? Calendar.current.date(byAdding: .day, value: 7, to: defaultTrialStart) ?? defaultTrialStart
        _draft = State(initialValue: sourceDraft)
        _amountText = State(initialValue: Self.amountString(for: sourceDraft.amount))
        _nextPaymentDateText = State(initialValue: Self.dateString(for: sourceDraft.nextPaymentDate, language: storedLanguage))
        _trialEnabled = State(initialValue: sourceDraft.trialStartDate != nil || sourceDraft.trialEndDate != nil)
        _trialStartDate = State(initialValue: defaultTrialStart)
        _trialEndDate = State(initialValue: defaultTrialEnd)
        _trialStartDateText = State(initialValue: Self.dateString(for: defaultTrialStart, language: storedLanguage))
        _trialEndDateText = State(initialValue: Self.dateString(for: defaultTrialEnd, language: storedLanguage))
        _selectedCategoryID = State(initialValue: sourceDraft.category?.id)
        _selectedPaymentMethodID = State(initialValue: sourceDraft.paymentMethod?.id)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Text(subscription == nil ? L10n.text("addSubscription", language: appLanguage) : L10n.text("editSubscription", language: appLanguage))
                    .font(.title2.bold())
                Spacer()
                EditorActionButton(title: L10n.text("cancel", language: appLanguage), isPrimary: false, action: onCancel)
                EditorActionButton(title: L10n.text("save", language: appLanguage), isPrimary: true, isDisabled: !canSave, action: saveDraft)
            }
            .padding(18)
            .background {
                if isSoftNeumorphic {
                    SoftNeumorphicRoundedSurface(
                        depth: .raised,
                        cornerRadius: 28,
                        fill: AnyShapeStyle(SoftNeumorphicTheme.surface)
                    )
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.bar)
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 20)

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    EditorSectionCard(title: L10n.text("details", language: appLanguage)) {
                        TextField(L10n.text("name", language: appLanguage), text: $draft.name)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .subPulseInsetSurface(isSoft: isSoftNeumorphic, cornerRadius: 16)

                        EditorDivider()

                        HStack(spacing: 12) {
                            EditorFieldLabel(L10n.text("amount", language: appLanguage))
                            TextField(L10n.text("amount", language: appLanguage), text: $amountText)
                                .textFieldStyle(.plain)
                                .multilineTextAlignment(.trailing)
                                .padding(10)
                                .frame(width: 170)
                                .subPulseInsetSurface(isSoft: isSoftNeumorphic, cornerRadius: 14)
                                .onChange(of: amountText) { _, newValue in
                                    draft.amount = Self.parseAmount(newValue)
                                }

                            Picker(L10n.text("currency", language: appLanguage), selection: $draft.currency) {
                                ForEach(CurrencyCatalog.supported, id: \.self) { currency in
                                    Text(currencyPickerTitle(for: currency)).tag(currency)
                                }
                            }
                            .frame(minWidth: 150)
                        }

                        EditorDivider()

                        VStack(alignment: .leading, spacing: 10) {
                            Text(L10n.text("nextPayment", language: appLanguage))
                                .font(.headline)
                                .foregroundStyle(.secondary)

                            HStack(spacing: 10) {
                                TextField((AppLanguage(rawValue: appLanguage) ?? .system).resolvedCode == "ru" ? "ДД.ММ.ГГГГ" : "YYYY-MM-DD", text: $nextPaymentDateText)
                                    .textFieldStyle(.plain)
                                    .padding(10)
                                    .frame(width: 180)
                                    .subPulseInsetSurface(isSoft: isSoftNeumorphic, cornerRadius: 14)
                                    .onChange(of: nextPaymentDateText) { _, newValue in
                                        if let date = Self.parseDate(newValue) {
                                            draft.nextPaymentDate = date
                                        }
                                    }

                                DatePicker(
                                    "",
                                    selection: $draft.nextPaymentDate,
                                    displayedComponents: [.date]
                                )
                                .labelsHidden()
                                .datePickerStyle(.compact)
                                .environment(\.locale, (AppLanguage(rawValue: appLanguage) ?? .system).resolvedCode == "ru" ? Locale(identifier: "ru_RU") : (AppLanguage(rawValue: appLanguage) ?? .system).locale)
                                .environment(\.calendar, L10n.calendar(language: appLanguage))
                                .onChange(of: draft.nextPaymentDate) { _, newValue in
                                    nextPaymentDateText = Self.dateString(for: newValue, language: appLanguage)
                                }

                                EditorActionButton(title: L10n.text("today", language: appLanguage), isPrimary: false) {
                                    draft.nextPaymentDate = Date()
                                    nextPaymentDateText = Self.dateString(for: draft.nextPaymentDate, language: appLanguage)
                                }
                            }
                        }

                        EditorDivider()

                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(L10n.text("trialPeriod", language: appLanguage))
                                        .font(.headline)
                                    Text(L10n.text("trialHint", language: appLanguage))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Toggle(L10n.text("trialEnabled", language: appLanguage), isOn: $trialEnabled)
                                    .toggleStyle(.switch)
                            }

                            if trialEnabled {
                                HStack(spacing: 10) {
                                    TrialDateField(
                                        title: L10n.text("trialStart", language: appLanguage),
                                        text: $trialStartDateText,
                                        date: $trialStartDate,
                                        language: appLanguage
                                    )

                                    TrialDateField(
                                        title: L10n.text("trialEnd", language: appLanguage),
                                        text: $trialEndDateText,
                                        date: $trialEndDate,
                                        language: appLanguage
                                    )
                                }
                                .transition(.move(edge: .top).combined(with: .opacity))
                            }
                        }
                        .padding(12)
                        .subPulseInsetSurface(isSoft: isSoftNeumorphic, cornerRadius: 18)

                        EditorDivider()

                        HStack {
                            EditorFieldLabel(L10n.text("period", language: appLanguage))
                            Spacer()
                            Picker(L10n.text("period", language: appLanguage), selection: $draft.billingPeriod) {
                                ForEach(BillingPeriod.allCases) { period in
                                    Text("\(period.emoji) \(period.localizedTitle(language: appLanguage))").tag(period)
                                }
                            }
                            .frame(minWidth: 190)
                        }
                    }

                    EditorSectionCard(title: L10n.text("organization", language: appLanguage)) {
                        HStack {
                            EditorFieldLabel(L10n.text("category", language: appLanguage))
                            Spacer()
                            Picker(L10n.text("category", language: appLanguage), selection: $selectedCategoryID) {
                                Text(L10n.text("none", language: appLanguage)).tag(UUID?.none)
                                ForEach(categories) { category in
                                    Text("\(EmojiIcon.emoji(for: category.iconName)) \(L10n.categoryName(category.name, language: appLanguage))")
                                        .tag(UUID?.some(category.id))
                                }
                            }
                            .frame(minWidth: 230)
                        }

                        EditorDivider()

                        PaymentMethodChooser(
                            methods: orderedPaymentMethods,
                            selectedID: selectedPaymentMethodID,
                            language: appLanguage,
                            onSelect: { selectedPaymentMethodID = $0 },
                            onAdd: { showPaymentMethodEditor = true }
                        )

                        if let paymentMethodStatus {
                            Text(paymentMethodStatus)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        EditorDivider()

                        HStack {
                            EditorFieldLabel(L10n.text("icon", language: appLanguage))
                            Spacer()
                            Picker(L10n.text("icon", language: appLanguage), selection: $draft.iconName) {
                                ForEach(EmojiIcon.subscriptionChoices, id: \.self) { icon in
                                    Text(icon).tag(icon)
                                }
                            }
                            .frame(minWidth: 170)
                        }
                    }

                    EditorSectionCard(title: L10n.text("notes", language: appLanguage)) {
                        TextEditor(text: $draft.notes)
                            .frame(minHeight: 100)
                            .scrollContentBackground(.hidden)
                            .padding(10)
                            .subPulseInsetSurface(isSoft: isSoftNeumorphic, cornerRadius: 16)

                        EditorDivider()

                        Toggle(L10n.text("active", language: appLanguage), isOn: $draft.isActive)
                    }
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 20)
            }

            if let validationMessage {
                HStack(spacing: 10) {
                    Text("⚠️")
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.text("requiredTitle", language: appLanguage))
                            .font(.caption.weight(.semibold))
                        Text(validationMessage)
                            .font(.caption)
                    }
                    Spacer()
                }
                .foregroundStyle(.secondary)
                .padding(12)
                .subPulseInsetSurface(isSoft: isSoftNeumorphic, cornerRadius: 16)
                .padding(.horizontal, 24)
                .padding(.bottom, 14)
            }
        }
        .frame(width: 560)
        .frame(minHeight: 680, maxHeight: 760)
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
        .sheet(isPresented: $showPaymentMethodEditor) {
            PaymentMethodEditorSheet(language: appLanguage, onSave: createPaymentMethod)
                .environment(\.isSoftNeumorphicTheme, isSoftNeumorphic)
        }
        .onChange(of: appLanguage) { _, newValue in
            nextPaymentDateText = Self.dateString(for: draft.nextPaymentDate, language: newValue)
            trialStartDateText = Self.dateString(for: trialStartDate, language: newValue)
            trialEndDateText = Self.dateString(for: trialEndDate, language: newValue)
        }
        .onChange(of: trialEnabled) { _, enabled in
            if enabled {
                trialStartDateText = Self.dateString(for: trialStartDate, language: appLanguage)
                trialEndDateText = Self.dateString(for: trialEndDate, language: appLanguage)
            }
        }
        .animation(.smooth(duration: 0.2), value: trialEnabled)
    }

    private static func parseAmount(_ value: String) -> Double {
        let normalized = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")

        return Double(normalized) ?? 0
    }

    private static func amountString(for amount: Double) -> String {
        amount == 0 ? "" : String(format: "%.2f", amount)
    }

    private static func parseDate(_ value: String) -> Date? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current

        for format in ["yyyy-MM-dd", "dd.MM.yyyy", "M/d/yyyy", "MM/dd/yyyy"] {
            formatter.dateFormat = format
            if let date = formatter.date(from: trimmed) {
                return Calendar.current.startOfDay(for: date)
            }
        }

        return nil
    }

    private static func dateString(for date: Date, language: String = AppLanguage.system.rawValue) -> String {
        L10n.editorDate(date, language: language)
    }

    private var orderedPaymentMethods: [PaymentMethod] {
        var methods = paymentMethods
        if let locallyCreatedPaymentMethod,
           !methods.contains(where: { $0.id == locallyCreatedPaymentMethod.id }) {
            methods.append(locallyCreatedPaymentMethod)
        }

        return methods.sorted { lhs, rhs in
            let lhsOrder = paymentMethodOrder(lhs.name)
            let rhsOrder = paymentMethodOrder(rhs.name)
            if lhsOrder == rhsOrder {
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
            return lhsOrder < rhsOrder
        }
    }

    private func paymentMethodOrder(_ name: String) -> Int {
        ["Apple Pay", "Google Pay", "Дебетовая карта", "Debit Card", "Кредитная карта", "Credit Card"].firstIndex(of: name) ?? Int.max
    }

    private func saveDraft() {
        draft.amount = parsedAmount
        if let parsedDate {
            draft.nextPaymentDate = parsedDate
        }
        draft.category = categories.first { $0.id == selectedCategoryID }
        draft.paymentMethod = orderedPaymentMethods.first { $0.id == selectedPaymentMethodID }
        if trialEnabled, let start = parsedTrialStartDate, let end = parsedTrialEndDate {
            draft.trialStartDate = start
            draft.trialEndDate = end
        } else {
            draft.trialStartDate = nil
            draft.trialEndDate = nil
        }
        onSave(draft)
    }

    private func currencyPickerTitle(for code: String) -> String {
        let info = CurrencyCatalog.info(for: code)
        return "\(info.flag) \(info.code)"
    }

    @MainActor
    private func createPaymentMethod(_ draft: PaymentMethodDraft) {
        let trimmedName = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        guard !orderedPaymentMethods.contains(where: { $0.name.localizedCaseInsensitiveCompare(trimmedName) == .orderedSame }) else {
            paymentMethodStatus = L10n.text("paymentMethodAlreadyExists", language: appLanguage)
            return
        }

        let last4 = draft.last4.trimmingCharacters(in: .whitespacesAndNewlines)
        let method = PaymentMethod(
            name: trimmedName,
            type: draft.type.storageType,
            last4: last4.isEmpty ? nil : last4,
            colorHex: draft.colorHex
        )
        modelContext.insert(method)

        do {
            try modelContext.save()
            locallyCreatedPaymentMethod = method
            selectedPaymentMethodID = method.id
            paymentMethodStatus = L10n.text("paymentMethodAdded", language: appLanguage)
        } catch {
            paymentMethodStatus = L10n.text("saveFailedMessage", language: appLanguage)
        }
    }
}

private struct EditorSectionCard<Content: View>: View {
    @Environment(\.isSoftNeumorphicTheme) private var isSoftNeumorphic

    let title: String
    @ViewBuilder let content: Content

    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .padding(.horizontal, 4)

            VStack(alignment: .leading, spacing: 12) {
                content
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                if isSoftNeumorphic {
                    SoftNeumorphicRoundedSurface(
                        depth: isHovering ? .pressed : .raisedSoft,
                        cornerRadius: 24,
                        fill: AnyShapeStyle(isHovering ? SoftNeumorphicTheme.surfaceInset : SoftNeumorphicTheme.surface)
                    )
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(nsColor: .controlBackgroundColor))
                }
            }
            .scaleEffect(isSoftNeumorphic && isHovering ? 0.996 : 1)
            .onHover { isHovering = $0 }
            .animation(.smooth(duration: 0.18), value: isHovering)
        }
    }
}

private struct EditorDivider: View {
    @Environment(\.isSoftNeumorphicTheme) private var isSoftNeumorphic

    var body: some View {
        Rectangle()
            .fill(isSoftNeumorphic ? SoftNeumorphicTheme.line : Color.secondary.opacity(0.16))
            .frame(height: 1)
    }
}

private struct TrialDateField: View {
    @Environment(\.isSoftNeumorphicTheme) private var isSoftNeumorphic

    let title: String
    @Binding var text: String
    @Binding var date: Date
    let language: String

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack(spacing: 7) {
                TextField(placeholder, text: $text)
                    .textFieldStyle(.plain)
                    .padding(9)
                    .frame(minWidth: 108)
                    .subPulseInsetSurface(isSoft: isSoftNeumorphic, cornerRadius: 13)
                    .onChange(of: text) { _, newValue in
                        if let parsed = Self.parseDate(newValue) {
                            date = parsed
                        }
                    }

                DatePicker("", selection: $date, displayedComponents: [.date])
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .environment(\.locale, locale)
                    .environment(\.calendar, L10n.calendar(language: language))
                    .onChange(of: date) { _, newValue in
                        text = L10n.editorDate(newValue, language: language)
                    }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var placeholder: String {
        (AppLanguage(rawValue: language) ?? .system).resolvedCode == "ru" ? "ДД.ММ.ГГГГ" : "YYYY-MM-DD"
    }

    private var locale: Locale {
        let appLanguage = AppLanguage(rawValue: language) ?? .system
        return appLanguage.resolvedCode == "ru" ? Locale(identifier: "ru_RU") : appLanguage.locale
    }

    private static func parseDate(_ value: String) -> Date? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current

        for format in ["yyyy-MM-dd", "dd.MM.yyyy", "M/d/yyyy", "MM/dd/yyyy"] {
            formatter.dateFormat = format
            if let date = formatter.date(from: trimmed) {
                return Calendar.current.startOfDay(for: date)
            }
        }

        return nil
    }
}

private struct EditorFieldLabel: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(.primary)
    }
}

private struct EditorActionButton: View {
    @Environment(\.isSoftNeumorphicTheme) private var isSoftNeumorphic

    let title: String
    var isPrimary = false
    var isDisabled = false
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.callout.weight(.semibold))
                .lineLimit(2)
                .minimumScaleFactor(0.82)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundStyle(isPrimary ? .white : Color.accentColor)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .frame(minWidth: 96)
                .background {
                    if isSoftNeumorphic {
                        SoftNeumorphicRoundedSurface(
                            depth: isHovering ? .pressed : .raisedSoft,
                            cornerRadius: 15,
                            fill: AnyShapeStyle(isPrimary ? Color.accentColor : (isHovering ? SoftNeumorphicTheme.surfaceInset : SoftNeumorphicTheme.surface))
                        )
                    } else {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isPrimary ? Color.accentColor : Color(nsColor: .controlBackgroundColor))
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

private struct PaymentMethodChooser: View {
    let methods: [PaymentMethod]
    let selectedID: UUID?
    let language: String
    let onSelect: (UUID?) -> Void
    let onAdd: () -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 168), spacing: 10)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.text("paymentMethod", language: language))
                .font(.headline)

            LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
                PaymentMethodChoiceButton(
                    title: L10n.text("none", language: language),
                    subtitle: nil,
                    symbol: "—",
                    isSelected: selectedID == nil,
                    action: { onSelect(nil) }
                )

                ForEach(methods) { method in
                    PaymentMethodChoiceButton(
                        title: L10n.paymentMethodName(method.name, language: language),
                        subtitle: method.last4.map { "\(PaymentMethodType.localizedTitle(for: method.type, language: language)) •••• \($0)" } ?? PaymentMethodType.localizedTitle(for: method.type, language: language),
                        symbol: PaymentMethodVisual.emoji(for: method),
                        isSelected: selectedID == method.id,
                        action: { onSelect(method.id) }
                    )
                }

                PaymentMethodChoiceButton(
                    title: L10n.text("addPaymentMethod", language: language),
                    subtitle: L10n.text("paymentTypeCustom", language: language),
                    symbol: "+",
                    isSelected: false,
                    isAccent: true,
                    action: onAdd
                )
            }
        }
    }
}

private struct PaymentMethodChoiceButton: View {
    @Environment(\.isSoftNeumorphicTheme) private var isSoftNeumorphic

    let title: String
    let subtitle: String?
    let symbol: String
    let isSelected: Bool
    var isAccent = false
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(symbol)
                    .font(.headline)
                    .frame(width: 30, height: 30)
                    .background {
                        Circle()
                            .fill(isAccent ? Color.accentColor.opacity(0.16) : SoftNeumorphicTheme.surfaceInset)
                    }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.callout.weight(.semibold))
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)
                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 66, alignment: .leading)
            .background {
                if isSoftNeumorphic {
                    SoftNeumorphicRoundedSurface(
                        depth: softDepth,
                        cornerRadius: 18,
                        fill: softFill
                    )
                } else {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(isSelected ? Color.accentColor.opacity(0.14) : Color(nsColor: .controlBackgroundColor))
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(isSelected ? Color.accentColor.opacity(0.78) : .clear, lineWidth: 1.6)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isSoftNeumorphic && isHovering ? 0.992 : 1)
        .onHover { isHovering = $0 }
        .animation(.smooth(duration: 0.18), value: isHovering)
    }

    private var softDepth: SoftNeumorphicDepth {
        if isSelected {
            return isHovering ? .raisedSoft : .inset
        }
        return isHovering ? .pressed : .raisedSoft
    }

    private var softFill: AnyShapeStyle {
        if isSelected {
            return AnyShapeStyle(isHovering ? SoftNeumorphicTheme.surface : SoftNeumorphicTheme.accentMuted)
        }
        if isAccent {
            return AnyShapeStyle(isHovering ? SoftNeumorphicTheme.surfaceInset : SoftNeumorphicTheme.surface)
        }
        return AnyShapeStyle(isHovering ? SoftNeumorphicTheme.surfaceInset : SoftNeumorphicTheme.surface)
    }
}
