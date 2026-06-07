import SwiftUI

struct SubscriptionPickerView: View {
    @Environment(\.isSoftNeumorphicTheme) private var isSoftNeumorphic
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.system.rawValue
    @AppStorage("appearance") private var appearance = AppAppearance.softNeumorphic.rawValue

    let categories: [Category]
    let paymentMethods: [PaymentMethod]
    let onAppStoreImport: () -> Void
    let onSelect: (SubscriptionDraft) -> Void
    let onCancel: () -> Void

    @State private var searchText = ""

    private var filtered: [SubscriptionPreset] {
        guard !searchText.isEmpty else { return SubscriptionPresetCatalog.all }
        return SubscriptionPresetCatalog.all.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.categoryName.localizedCaseInsensitiveContains(searchText) ||
                L10n.categoryName($0.categoryName, language: appLanguage).localizedCaseInsensitiveContains(searchText)
        }
    }

    private var popular: [SubscriptionPreset] {
        filtered.filter(\.isPopular)
    }

    private var allServices: [SubscriptionPreset] {
        filtered.filter { !$0.isPopular }
    }

    private var usesSoftNeumorphic: Bool {
        isSoftNeumorphic || (AppAppearance(rawValue: appearance) ?? .softNeumorphic).isSoftNeumorphic
    }

    private let columns = Array(repeating: GridItem(.fixed(148), spacing: 8), count: 3)

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    importSection
                    if !popular.isEmpty {
                        serviceSection(title: L10n.text("popularServices", language: appLanguage), items: popular)
                    }
                    if !allServices.isEmpty {
                        serviceSection(title: L10n.text("allServices", language: appLanguage), items: allServices)
                    }
                }
                .padding(14)
                .padding(.bottom, 62)
            }

            bottomBar
        }
        .frame(width: 500, height: 640)
        .background {
            if usesSoftNeumorphic {
                Rectangle()
                    .fill(SoftNeumorphicTheme.pageBackground)
                    .ignoresSafeArea()
            }
        }
    }

    private var importSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.text("automaticImportFrom", language: appLanguage))
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
            HStack(spacing: 12) {
                ImportPill(
                    title: L10n.text("screenshotTextImportSource", language: appLanguage),
                    emoji: "",
                    status: L10n.text("activeImport", language: appLanguage),
                    isSoft: usesSoftNeumorphic,
                    action: onAppStoreImport
                )
                Spacer(minLength: 0)
            }
        }
    }

    private func serviceSection(title: String, items: [SubscriptionPreset]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(items) { preset in
                    Button {
                        onSelect(preset.draft(categories: categories, paymentMethods: paymentMethods))
                    } label: {
                        ServicePresetCard(
                            title: preset.name,
                            subtitle: MoneyFormatter.string(preset.amount),
                            iconName: preset.iconName,
                            isSoft: usesSoftNeumorphic
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 12) {
            Text("🔎")
            TextField(L10n.text("searchServices", language: appLanguage), text: $searchText)
                .textFieldStyle(.plain)
                .padding(.horizontal, usesSoftNeumorphic ? 10 : 0)
                .padding(.vertical, usesSoftNeumorphic ? 7 : 0)
                .subPulseInsetSurface(isSoft: usesSoftNeumorphic, cornerRadius: 999, fallback: AnyShapeStyle(Color.clear))
            SoftModalButton(title: L10n.text("customSubscription", language: appLanguage), isSoft: usesSoftNeumorphic) {
                onSelect(SubscriptionDraft())
            }
            SoftModalButton(title: L10n.text("cancel", language: appLanguage), isSoft: usesSoftNeumorphic, action: onCancel)
        }
        .padding(12)
        .background {
            if usesSoftNeumorphic {
                SoftNeumorphicRoundedSurface(
                    depth: .raised,
                    cornerRadius: 0,
                    fill: AnyShapeStyle(SoftNeumorphicTheme.surface)
                )
            } else {
                Rectangle()
                    .fill(.regularMaterial)
            }
        }
    }
}

private struct ServicePresetCard: View {
    let title: String
    let subtitle: String
    let iconName: String
    let isSoft: Bool

    @State private var isHovering = false

    var body: some View {
        VStack(spacing: 7) {
            BrandIcon(name: title, iconName: iconName, colorHex: "#007AFF", size: 46)
            Text(title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, minHeight: 112)
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
        .background {
            if isSoft {
                SoftNeumorphicRoundedSurface(
                    depth: isHovering ? .pressed : .raisedSoft,
                    cornerRadius: 22,
                    fill: AnyShapeStyle(isHovering ? SoftNeumorphicTheme.surfaceInset : SoftNeumorphicTheme.surface)
                )
            } else {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(nsColor: .controlBackgroundColor).opacity(isHovering ? 0.92 : 0.72))
            }
        }
        .scaleEffect(isSoft && isHovering ? 0.992 : (isHovering ? 1.01 : 1))
        .onHover { isHovering = $0 }
        .animation(.smooth(duration: 0.18), value: isHovering)
    }
}

private struct SoftModalButton: View {
    let title: String
    let isSoft: Bool
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.callout.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .frame(minWidth: 72)
                .background {
                    if isSoft {
                        SoftNeumorphicRoundedSurface(
                            depth: isHovering ? .pressed : .raisedSoft,
                            cornerRadius: 14,
                            fill: AnyShapeStyle(isHovering ? SoftNeumorphicTheme.surfaceInset : SoftNeumorphicTheme.surface)
                        )
                    } else {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(nsColor: .controlBackgroundColor).opacity(isHovering ? 0.92 : 0.72))
                    }
                }
        }
        .buttonStyle(.plain)
        .scaleEffect(isSoft && isHovering ? 0.98 : 1)
        .onHover { isHovering = $0 }
        .animation(.smooth(duration: 0.18), value: isHovering)
    }
}

private struct ImportPill: View {
    @State private var isHovering = false

    let title: String
    let emoji: String
    let status: String
    let isSoft: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(emoji)
                Text(title)
                    .font(.headline)
                Text(status)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.green.gradient, in: Capsule())
                Image(systemName: "arrow.up.doc")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
            }
            .frame(width: 244)
            .padding(.vertical, 10)
            .background {
                if isSoft {
                    SoftNeumorphicRoundedSurface(
                        depth: isHovering ? .pressed : .raisedSoft,
                        cornerRadius: 18,
                        fill: AnyShapeStyle(isHovering ? SoftNeumorphicTheme.surfaceInset : SoftNeumorphicTheme.accentMuted)
                    )
                } else {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.accentColor.opacity(0.12))
                }
            }
            .overlay {
                if !isSoft {
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.accentColor.opacity(0.26), lineWidth: 1)
                }
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isSoft && isHovering ? 0.992 : 1)
        .onHover { isHovering = $0 }
        .animation(.smooth(duration: 0.18), value: isHovering)
    }
}
