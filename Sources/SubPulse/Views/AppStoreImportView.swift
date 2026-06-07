import SwiftUI
import UniformTypeIdentifiers

struct AppStoreImportView: View {
    @Environment(\.isSoftNeumorphicTheme) private var isSoftNeumorphic
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.system.rawValue

    let categories: [Category]
    let paymentMethods: [PaymentMethod]
    let existingSubscriptionNames: Set<String>
    let defaultDate: Date?
    let onConfirm: ([SubscriptionDraft]) -> Void
    let onCancel: () -> Void

    @State private var importText = ""
    @State private var candidates: [AppStoreImportResult] = []
    @State private var isRecognizing = false
    @State private var isFileImporterPresented = false
    @State private var errorMessage: String?

    private var selectedCandidates: [AppStoreImportResult] {
        candidates.filter { $0.isSelected && !alreadyExists($0.name) }
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            HStack(alignment: .top, spacing: 16) {
                recognitionPanel
                confirmationPanel
            }
            .padding(18)
        }
        .frame(width: 760, height: 660)
        .background {
            if isSoftNeumorphic {
                Rectangle()
                    .fill(SoftNeumorphicTheme.pageBackground)
                    .ignoresSafeArea()
            }
        }
        .fileImporter(
            isPresented: $isFileImporterPresented,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.text("appStoreImportTitle", language: appLanguage))
                    .font(.title2.bold())
                Text(L10n.text("appStoreImportSubtitle", language: appLanguage))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(L10n.text("cancel", language: appLanguage), action: onCancel)
            Button(L10n.text("importSelected", language: appLanguage)) {
                onConfirm(selectedCandidates.map(draft(from:)))
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedCandidates.isEmpty)
        }
        .padding()
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

    private var recognitionPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Button {
                    isFileImporterPresented = true
                } label: {
                    Label(L10n.text("chooseAppStoreScreenshot", language: appLanguage), systemImage: "photo.on.rectangle")
                }

                Button {
                    parseText()
                } label: {
                    Label(L10n.text("recognizeSubscriptions", language: appLanguage), systemImage: "text.viewfinder")
                }
                .disabled(importText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isRecognizing)
            }

            ZStack(alignment: .topLeading) {
                TextEditor(text: $importText)
                    .font(.system(.body, design: .rounded))
                    .frame(minHeight: 410)
                    .padding(8)
                    .subPulseInsetSurface(
                        isSoft: isSoftNeumorphic,
                        cornerRadius: 18,
                        fallback: AnyShapeStyle(Color(nsColor: .textBackgroundColor))
                    )

                if importText.isEmpty {
                    Text(L10n.text("pasteAppStoreText", language: appLanguage))
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 18)
                        .allowsHitTesting(false)
                }

                if isRecognizing {
                    ProgressView()
                        .controlSize(.large)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .subPulseRaisedSurface(isSoft: isSoftNeumorphic, cornerRadius: 18)
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .frame(width: 360)
    }

    private var confirmationPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(L10n.text("recognizedSubscriptions", language: appLanguage))
                    .font(.headline)
                Spacer()
                Text(String(format: L10n.text("selectedCountFormat", language: appLanguage), selectedCandidates.count))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            if candidates.isEmpty {
                ContentUnavailableView(
                    L10n.text("noRecognizedSubscriptions", language: appLanguage),
                    systemImage: "text.magnifyingglass",
                    description: Text(L10n.text("appStoreImportEmptyHint", language: appLanguage))
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach($candidates) { $candidate in
                            AppStoreImportRow(
                                candidate: $candidate,
                                alreadyExists: alreadyExists(candidate.name)
                            )
                        }
                    }
                    .padding(2)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(14)
        .subPulseRaisedSurface(
            isSoft: isSoftNeumorphic,
            cornerRadius: 22,
            fallback: AnyShapeStyle(Color(nsColor: .controlBackgroundColor).opacity(0.7))
        )
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        guard case .success(let urls) = result, let url = urls.first else { return }

        Task {
            await recognize(url)
        }
    }

    @MainActor
    private func recognize(_ url: URL) async {
        isRecognizing = true
        errorMessage = nil

        let didStart = url.startAccessingSecurityScopedResource()
        defer {
            if didStart {
                url.stopAccessingSecurityScopedResource()
            }
        }

        do {
            importText = try await TextRecognitionService.recognizeText(in: url)
            parseText()
        } catch {
            errorMessage = L10n.text("recognitionFailed", language: appLanguage)
        }

        isRecognizing = false
    }

    private func parseText() {
        let parsed = AppStoreImportParser.parse(importText)
        candidates = parsed.map { result in
            var adjusted = result
            if let preset = preset(for: result.name) {
                adjusted.name = preset.name
                adjusted.amount = result.amount > 0 ? result.amount : preset.amount
                adjusted.currency = result.currency
                adjusted.billingPeriod = result.billingPeriod
            }
            adjusted.isSelected = !alreadyExists(adjusted.name)
            return adjusted
        }
        errorMessage = candidates.isEmpty ? L10n.text("noImportText", language: appLanguage) : nil
    }

    private func draft(from result: AppStoreImportResult) -> SubscriptionDraft {
        if let preset = preset(for: result.name) {
            var draft = preset.draft(categories: categories, paymentMethods: paymentMethods)
            draft.amount = result.amount
            draft.currency = result.currency
            draft.billingPeriod = result.billingPeriod
            draft.nextPaymentDate = result.nextPaymentDate ?? defaultNextPaymentDate
            draft.notes = importNote(from: result)
            return draft
        }

        var draft = SubscriptionDraft()
        draft.name = result.name
        draft.amount = result.amount
        draft.currency = result.currency
        draft.billingPeriod = result.billingPeriod
        draft.nextPaymentDate = result.nextPaymentDate ?? defaultNextPaymentDate
        draft.category = categories.first { $0.name == "Software" } ?? categories.first
        draft.paymentMethod = paymentMethods.first
        draft.iconName = "appstore"
        draft.notes = importNote(from: result)
        return draft
    }

    private var defaultNextPaymentDate: Date {
        if let defaultDate {
            return Calendar.current.startOfDay(for: defaultDate)
        }
        return Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    }

    private func importNote(from result: AppStoreImportResult) -> String {
        "\(L10n.text("importedFromAppStoreOCR", language: appLanguage))\n\n\(result.sourceText)"
    }

    private func preset(for name: String) -> SubscriptionPreset? {
        let normalizedName = name.normalizedImportName
        return SubscriptionPresetCatalog.all.first {
            let normalizedPreset = $0.name.normalizedImportName
            return normalizedName == normalizedPreset ||
                normalizedName.contains(normalizedPreset) ||
                normalizedPreset.contains(normalizedName)
        }
    }

    private func alreadyExists(_ name: String) -> Bool {
        existingSubscriptionNames.contains(SubscriptionNameNormalizer.normalized(name))
    }
}

private struct AppStoreImportRow: View {
    @Binding var candidate: AppStoreImportResult
    let alreadyExists: Bool
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.system.rawValue

    var body: some View {
        HStack(spacing: 10) {
            Toggle("", isOn: $candidate.isSelected)
                .labelsHidden()
                .disabled(alreadyExists)

            BrandIcon(name: candidate.name, iconName: "appstore", size: 36)

            VStack(alignment: .leading, spacing: 7) {
                TextField(L10n.text("name", language: appLanguage), text: $candidate.name)
                    .textFieldStyle(.roundedBorder)
                    .disabled(alreadyExists)

                HStack(spacing: 8) {
                    TextField(
                        L10n.text("amount", language: appLanguage),
                        value: $candidate.amount,
                        format: .number.precision(.fractionLength(2))
                    )
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 92)
                    .disabled(alreadyExists)

                    Picker("", selection: $candidate.currency) {
                        ForEach(CurrencyCatalog.supported, id: \.self) { currency in
                            Text(currency).tag(currency)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 86)
                    .disabled(alreadyExists)

                    Picker("", selection: $candidate.billingPeriod) {
                        ForEach(BillingPeriod.allCases) { period in
                            Text(period.localizedTitle(language: appLanguage)).tag(period)
                        }
                    }
                    .labelsHidden()
                    .disabled(alreadyExists)
                }

                if alreadyExists {
                    Text(L10n.text("alreadyExists", language: appLanguage))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .opacity(alreadyExists ? 0.62 : 1)
    }
}

private extension String {
    var normalizedImportName: String {
        lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "+", with: "")
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: "-", with: "")
    }
}
