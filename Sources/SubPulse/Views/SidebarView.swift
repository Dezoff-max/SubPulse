import SwiftUI

struct SidebarView: View {
    @Environment(\.isSoftNeumorphicTheme) private var isSoftNeumorphic
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.system.rawValue
    @Binding var selection: AppDestination?

    private let destinations: [AppDestination] = [
        .dashboard,
        .subscriptions,
        .analytics,
        .settings
    ]

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                ForEach(destinations) { destination in
                    SidebarDestinationRow(
                        destination: destination,
                        title: destination.localizedTitle(language: appLanguage),
                        isSelected: selection == destination,
                        isSoft: isSoftNeumorphic
                    ) {
                        withAnimation(.snappy(duration: 0.22)) {
                            selection = destination
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 14)

            Spacer(minLength: 0)
        }
        .background {
            if isSoftNeumorphic {
                SoftNeumorphicTheme.background
                    .ignoresSafeArea()
            } else {
                Color(nsColor: .underPageBackgroundColor)
                    .ignoresSafeArea()
            }
        }
        .navigationTitle("SubPulse")
        .toolbar {
            ToolbarItem {
                Button {
                    NotificationCenter.default.post(name: .showSubscriptionEditor, object: nil)
                } label: {
                    Text("➕")
                }
                .help(L10n.text("addSubscription", language: appLanguage))
            }
        }
    }
}

private struct SidebarDestinationRow: View {
    let destination: AppDestination
    let title: String
    let isSelected: Bool
    let isSoft: Bool
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(destination.emoji)
                    .font(.title3)
                    .frame(width: 24)
                Text(title)
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.88)
                    .fixedSize(horizontal: true, vertical: false)
                Spacer(minLength: 0)
            }
            .foregroundStyle(foreground)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .frame(minWidth: 176, maxWidth: .infinity, alignment: .leading)
            .background(rowBackground)
            .contentShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .scaleEffect(scale)
        .onHover { isHovering = $0 }
        .animation(.smooth(duration: 0.18), value: isHovering)
        .animation(.smooth(duration: 0.18), value: isSelected)
        .accessibilityLabel(title)
    }

    @ViewBuilder
    private var rowBackground: some View {
        if isSoft {
            SoftNeumorphicRoundedSurface(
                depth: softDepth,
                cornerRadius: 16,
                fill: AnyShapeStyle(softFill)
            )
        } else if isSelected {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.accentColor.gradient)
        } else if isHovering {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.secondary.opacity(0.12))
        }
    }

    private var softDepth: SoftNeumorphicDepth {
        if isSelected {
            return isHovering ? .pressed : .raisedSoft
        }
        return isHovering ? .raisedSoft : .inset
    }

    private var softFill: some ShapeStyle {
        if isSelected {
            return AnyShapeStyle(isHovering ? SoftNeumorphicTheme.surfaceInset : SoftNeumorphicTheme.accentMuted)
        }
        return AnyShapeStyle(isHovering ? SoftNeumorphicTheme.surface : SoftNeumorphicTheme.surfaceInset.opacity(0.70))
    }

    private var foreground: some ShapeStyle {
        if !isSoft && isSelected {
            return AnyShapeStyle(Color.white)
        }
        return AnyShapeStyle(Color.primary)
    }

    private var scale: CGFloat {
        if isSoft {
            return isSelected && isHovering ? 0.985 : (isHovering ? 1.01 : 1)
        }
        return isHovering ? 1.01 : 1
    }
}
