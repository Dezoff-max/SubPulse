import SwiftUI

private struct SoftNeumorphicThemeEnabledKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var isSoftNeumorphicTheme: Bool {
        get { self[SoftNeumorphicThemeEnabledKey.self] }
        set { self[SoftNeumorphicThemeEnabledKey.self] = newValue }
    }
}

enum SoftNeumorphicTheme {
    static let background = Color(lightHex: "#e8ecf1", darkHex: "#1e232b")
    static let surface = Color(lightHex: "#e8ecf1", darkHex: "#252b34")
    static let surfaceAlt = Color(lightHex: "#eef2f7", darkHex: "#2c3440")
    static let surfaceInset = Color(lightHex: "#dde3ea", darkHex: "#1a1f27")
    static let text = Color(lightHex: "#2d3142", darkHex: "#eef3fb")
    static let mutedText = Color(lightHex: "#8b8fa5", darkHex: "#97a2b6")
    static let line = Color(lightHex: "#c5c9ce", darkHex: "#8594aa").opacity(0.35)
    static let accent = Color(lightHex: "#6b7fd7", darkHex: "#7d90ff")
    static let accentLight = Color(lightHex: "#818cf8", darkHex: "#9dacf9")
    static let accentMuted = Color(lightHex: "#6b7fd7", darkHex: "#7d90ff").opacity(0.16)
    static let darkShadow = Color(lightHex: "#c5c9ce", darkHex: "#151920")
    static let lightShadow = Color(lightHex: "#ffffff", darkHex: "#313947")

    static var pageBackground: some ShapeStyle {
        LinearGradient(
            colors: [
                Color(lightHex: "#edf1f6", darkHex: "#252b34"),
                background,
                Color(lightHex: "#e4e9ef", darkHex: "#1a1f27")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

enum SoftNeumorphicDepth {
    case raised
    case raisedSoft
    case inset
    case pressed
}

struct SoftNeumorphicRoundedSurface: View {
    let depth: SoftNeumorphicDepth
    let cornerRadius: CGFloat
    let fill: AnyShapeStyle

    init(
        depth: SoftNeumorphicDepth,
        cornerRadius: CGFloat,
        fill: AnyShapeStyle = AnyShapeStyle(SoftNeumorphicTheme.surface)
    ) {
        self.depth = depth
        self.cornerRadius = cornerRadius
        self.fill = fill
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius)

        shape
            .fill(fill)
            .overlay {
                if depth == .inset || depth == .pressed {
                    insetHighlights(shape: shape)
                }
            }
            .overlay {
                shape
                    .stroke(SoftNeumorphicTheme.line.opacity(depth == .inset ? 0.38 : 0.18), lineWidth: 0.7)
            }
            .modifier(SoftNeumorphicOuterShadow(depth: depth))
    }

    private func insetHighlights(shape: RoundedRectangle) -> some View {
        ZStack {
            shape
                .stroke(SoftNeumorphicTheme.lightShadow.opacity(0.95), lineWidth: 3)
                .blur(radius: 3)
                .offset(x: -3, y: -3)
                .mask(
                    shape.fill(
                        LinearGradient(
                            colors: [.black, .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                )

            shape
                .stroke(SoftNeumorphicTheme.darkShadow.opacity(0.82), lineWidth: 4)
                .blur(radius: 4)
                .offset(x: 4, y: 4)
                .mask(
                    shape.fill(
                        LinearGradient(
                            colors: [.clear, .black],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                )
        }
        .allowsHitTesting(false)
    }
}

private struct SoftNeumorphicRaisedModifier: ViewModifier {
    @State private var isHovering = false

    let isEnabled: Bool
    let cornerRadius: CGFloat
    let fallback: AnyShapeStyle

    func body(content: Content) -> some View {
        content
            .background {
                if isEnabled {
                    SoftNeumorphicRoundedSurface(
                        depth: isHovering ? .pressed : .raisedSoft,
                        cornerRadius: cornerRadius,
                        fill: AnyShapeStyle(isHovering ? SoftNeumorphicTheme.surfaceInset : SoftNeumorphicTheme.surface)
                    )
                } else {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(fallback)
                }
            }
            .onHover { hovering in
                guard isEnabled else { return }
                isHovering = hovering
            }
            .animation(.smooth(duration: 0.18), value: isHovering)
    }
}

private struct SoftNeumorphicInsetModifier: ViewModifier {
    @State private var isHovering = false

    let isEnabled: Bool
    let cornerRadius: CGFloat
    let fallback: AnyShapeStyle

    func body(content: Content) -> some View {
        content
            .background {
                if isEnabled {
                    SoftNeumorphicRoundedSurface(
                        depth: isHovering ? .raisedSoft : .inset,
                        cornerRadius: cornerRadius,
                        fill: AnyShapeStyle(isHovering ? SoftNeumorphicTheme.surface : SoftNeumorphicTheme.surfaceInset)
                    )
                } else {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(fallback)
                }
            }
            .onHover { hovering in
                guard isEnabled else { return }
                isHovering = hovering
            }
            .animation(.smooth(duration: 0.18), value: isHovering)
    }
}

private struct SoftNeumorphicOuterShadow: ViewModifier {
    let depth: SoftNeumorphicDepth

    func body(content: Content) -> some View {
        switch depth {
        case .raised:
            content
                .shadow(color: SoftNeumorphicTheme.darkShadow.opacity(0.95), radius: 20, x: 10, y: 10)
                .shadow(color: SoftNeumorphicTheme.lightShadow.opacity(0.98), radius: 20, x: -10, y: -10)
        case .raisedSoft:
            content
                .shadow(color: SoftNeumorphicTheme.darkShadow.opacity(0.85), radius: 13, x: 7, y: 7)
                .shadow(color: SoftNeumorphicTheme.lightShadow.opacity(0.98), radius: 13, x: -7, y: -7)
        case .inset:
            content
        case .pressed:
            content
                .shadow(color: SoftNeumorphicTheme.darkShadow.opacity(0.20), radius: 3, x: 1, y: 1)
        }
    }
}

private struct SoftNeumorphicRaisedShadow: ViewModifier {
    let isEnabled: Bool

    func body(content: Content) -> some View {
        content.modifier(isEnabled ? SoftNeumorphicOuterShadow(depth: .raisedSoft) : SoftNeumorphicOuterShadow(depth: .inset))
    }
}

private struct SoftNeumorphicInsetShadow: ViewModifier {
    let isEnabled: Bool

    func body(content: Content) -> some View {
        if isEnabled {
            content
                .shadow(color: SoftNeumorphicTheme.lightShadow.opacity(0.84), radius: 8, x: -4, y: -4)
                .shadow(color: SoftNeumorphicTheme.darkShadow.opacity(0.72), radius: 8, x: 4, y: 4)
        } else {
            content
        }
    }
}

extension View {
    func subPulseRaisedSurface(
        isSoft: Bool,
        cornerRadius: CGFloat,
        fallback: AnyShapeStyle = AnyShapeStyle(.regularMaterial)
    ) -> some View {
        modifier(SoftNeumorphicRaisedModifier(isEnabled: isSoft, cornerRadius: cornerRadius, fallback: fallback))
    }

    func subPulseInsetSurface(
        isSoft: Bool,
        cornerRadius: CGFloat,
        fallback: AnyShapeStyle = AnyShapeStyle(.thinMaterial)
    ) -> some View {
        modifier(SoftNeumorphicInsetModifier(isEnabled: isSoft, cornerRadius: cornerRadius, fallback: fallback))
    }

    func softNeumorphicRaisedShadow(isEnabled: Bool) -> some View {
        modifier(SoftNeumorphicRaisedShadow(isEnabled: isEnabled))
    }

    func softNeumorphicInsetShadow(isEnabled: Bool) -> some View {
        modifier(SoftNeumorphicInsetShadow(isEnabled: isEnabled))
    }
}
