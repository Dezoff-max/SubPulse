import SwiftUI

struct BrandStyle {
    let mark: String
    let background: Color
    let foreground: Color
    let isMonogram: Bool
}

enum BrandIconResolver {
    static func style(name: String, fallbackIcon: String, fallbackColor: String) -> BrandStyle {
        let normalized = name.lowercased()

        if normalized.contains("netflix") {
            return BrandStyle(mark: "N", background: Color(red: 0.9, green: 0.02, blue: 0.04), foreground: .white, isMonogram: true)
        }
        if normalized.contains("spotify") {
            return BrandStyle(mark: "♫", background: Color(red: 0.1, green: 0.75, blue: 0.32), foreground: .black, isMonogram: false)
        }
        if normalized.contains("youtube") {
            return BrandStyle(mark: "▶", background: Color(red: 1.0, green: 0.0, blue: 0.0), foreground: .white, isMonogram: false)
        }
        if normalized.contains("apple music") {
            return BrandStyle(mark: "♪", background: Color(red: 0.98, green: 0.12, blue: 0.34), foreground: .white, isMonogram: false)
        }
        if normalized.contains("apple one") {
            return BrandStyle(mark: "1", background: Color(red: 0.42, green: 0.22, blue: 0.95), foreground: .white, isMonogram: true)
        }
        if normalized.contains("apple arcade") {
            return BrandStyle(mark: "🎮", background: Color(red: 0.06, green: 0.06, blue: 0.07), foreground: .white, isMonogram: false)
        }
        if normalized.contains("apple care") {
            return BrandStyle(mark: "✚", background: Color(red: 0.0, green: 0.48, blue: 1.0), foreground: .white, isMonogram: false)
        }
        if normalized.contains("apple developer") {
            return BrandStyle(mark: "⌘", background: Color(red: 0.07, green: 0.07, blue: 0.08), foreground: .white, isMonogram: false)
        }
        if normalized.contains("apple fitness") {
            return BrandStyle(mark: "●", background: Color(red: 0.98, green: 0.34, blue: 0.12), foreground: Color(red: 0.74, green: 1.0, blue: 0.08), isMonogram: false)
        }
        if normalized.contains("apple tv") {
            return BrandStyle(mark: "tv", background: .black, foreground: .white, isMonogram: true)
        }
        if normalized.contains("icloud") {
            return BrandStyle(mark: "☁", background: Color(red: 0.18, green: 0.48, blue: 1.0), foreground: .white, isMonogram: false)
        }
        if normalized.contains("apple") {
            return BrandStyle(mark: "", background: Color(red: 0.1, green: 0.1, blue: 0.12), foreground: .white, isMonogram: false)
        }
        if normalized.contains("google") {
            return BrandStyle(mark: "G", background: Color(red: 0.98, green: 0.98, blue: 1.0), foreground: Color(red: 0.12, green: 0.38, blue: 0.92), isMonogram: true)
        }
        if normalized.contains("chatgpt") || normalized.contains("openai") {
            return BrandStyle(mark: "openaiGlyph", background: .white, foreground: .black, isMonogram: false)
        }
        if normalized.contains("app store") {
            return BrandStyle(mark: "A", background: Color(red: 0.0, green: 0.48, blue: 1.0), foreground: .white, isMonogram: true)
        }
        if normalized.contains("claude") {
            return BrandStyle(mark: "✺", background: Color(red: 0.8, green: 0.42, blue: 0.28), foreground: .white, isMonogram: false)
        }
        if normalized.contains("cursor") {
            return BrandStyle(mark: "◆", background: Color(red: 0.1, green: 0.1, blue: 0.12), foreground: .white, isMonogram: false)
        }
        if normalized.contains("linkedin") {
            return BrandStyle(mark: "in", background: Color(red: 0.0, green: 0.46, blue: 0.71), foreground: .white, isMonogram: true)
        }
        if normalized.contains("prime video") {
            return BrandStyle(mark: "▶", background: Color(red: 0.02, green: 0.4, blue: 0.86), foreground: .white, isMonogram: false)
        }
        if normalized.contains("amazon music") {
            return BrandStyle(mark: "♫", background: Color(red: 0.0, green: 0.67, blue: 0.87), foreground: .white, isMonogram: false)
        }
        if normalized.contains("amazon") {
            return BrandStyle(mark: "a", background: Color(red: 0.08, green: 0.16, blue: 0.28), foreground: Color(red: 1.0, green: 0.6, blue: 0.1), isMonogram: true)
        }
        if normalized.contains("1password") {
            return BrandStyle(mark: "1", background: Color(red: 0.12, green: 0.28, blue: 0.65), foreground: .white, isMonogram: true)
        }
        if normalized.contains("adobe") {
            return BrandStyle(mark: "▲", background: Color(red: 0.92, green: 0.05, blue: 0.08), foreground: .white, isMonogram: false)
        }
        if normalized.contains("figma") {
            return BrandStyle(mark: "●", background: Color(red: 0.64, green: 0.31, blue: 1.0), foreground: Color(red: 0.14, green: 0.93, blue: 0.57), isMonogram: false)
        }
        if normalized.contains("notion") {
            return BrandStyle(mark: "N", background: .white, foreground: .black, isMonogram: true)
        }
        if normalized.contains("canva") {
            return BrandStyle(mark: "C", background: Color(red: 0.0, green: 0.78, blue: 0.88), foreground: .white, isMonogram: true)
        }
        if normalized.contains("telegram") {
            return BrandStyle(mark: "✈", background: Color(red: 0.12, green: 0.62, blue: 0.93), foreground: .white, isMonogram: false)
        }
        if normalized.contains("discord") {
            return BrandStyle(mark: "⌁", background: Color(red: 0.35, green: 0.39, blue: 0.95), foreground: .white, isMonogram: false)
        }
        if normalized.contains("audible") {
            return BrandStyle(mark: "☊", background: Color(red: 0.98, green: 0.55, blue: 0.08), foreground: .white, isMonogram: false)
        }
        if normalized.contains("calm") {
            return BrandStyle(mark: "☾", background: Color(red: 0.16, green: 0.38, blue: 0.96), foreground: .white, isMonogram: false)
        }
        if fallbackIcon == "appstore" {
            return BrandStyle(mark: "A", background: Color(red: 0.0, green: 0.48, blue: 1.0), foreground: .white, isMonogram: true)
        }

        return BrandStyle(
            mark: EmojiIcon.emoji(for: fallbackIcon),
            background: Color(hex: fallbackColor),
            foreground: .white,
            isMonogram: false
        )
    }
}

struct BrandIcon: View {
    let name: String
    let iconName: String
    var colorHex: String = "#007AFF"
    var size: CGFloat = 42

    private var style: BrandStyle {
        BrandIconResolver.style(name: name, fallbackIcon: iconName, fallbackColor: colorHex)
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(style.background.gradient)
                .overlay {
                    Circle()
                        .stroke(.white.opacity(0.28), lineWidth: 1)
                }
                .shadow(color: style.background.opacity(0.28), radius: size * 0.24, y: size * 0.12)

            if style.mark == "openaiGlyph" {
                ChatGPTKnot(size: size, color: style.foreground)
            } else if style.mark == "G" {
                googleMark
            } else {
                Text(style.mark)
                    .font(style.isMonogram ? .system(size: size * 0.38, weight: .black, design: .rounded) : .system(size: size * 0.42, weight: .bold))
                    .foregroundStyle(style.foreground)
            }
        }
        .frame(width: size, height: size)
        .accessibilityLabel(name)
    }

    private var googleMark: some View {
        Text("G")
            .font(.system(size: size * 0.48, weight: .black, design: .rounded))
            .foregroundStyle(
                LinearGradient(
                    colors: [.blue, .red, .yellow, .green],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
}

private struct ChatGPTKnot: View {
    let size: CGFloat
    let color: Color

    var body: some View {
        ZStack {
            ForEach(0..<6, id: \.self) { index in
                KnotArm()
                    .stroke(color, style: StrokeStyle(lineWidth: size * 0.064, lineCap: .round, lineJoin: .round))
                    .frame(width: size * 0.62, height: size * 0.62)
                    .rotationEffect(.degrees(Double(index) * 60))
            }

            Circle()
                .stroke(color, lineWidth: size * 0.048)
                .frame(width: size * 0.18, height: size * 0.18)
        }
        .frame(width: size * 0.7, height: size * 0.7)
        .rotationEffect(.degrees(-18))
    }
}

private struct KnotArm: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        path.move(to: CGPoint(x: w * 0.50, y: h * 0.10))
        path.addCurve(
            to: CGPoint(x: w * 0.78, y: h * 0.25),
            control1: CGPoint(x: w * 0.64, y: h * 0.10),
            control2: CGPoint(x: w * 0.74, y: h * 0.15)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.76, y: h * 0.50),
            control1: CGPoint(x: w * 0.86, y: h * 0.36),
            control2: CGPoint(x: w * 0.84, y: h * 0.46)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.55, y: h * 0.58),
            control1: CGPoint(x: w * 0.69, y: h * 0.55),
            control2: CGPoint(x: w * 0.62, y: h * 0.58)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.42, y: h * 0.50),
            control1: CGPoint(x: w * 0.48, y: h * 0.58),
            control2: CGPoint(x: w * 0.44, y: h * 0.55)
        )

        return path
    }
}
