import SwiftUI

enum EmojiIcon {
    static let subscriptionChoices = ["💬", "☁️", "📦", "✨", "🎬", "🎵", "💳", "📚", "🎮", "🧠", "🛡️", "🏋️"]

    static func emoji(for value: String) -> String {
        if value.containsEmoji {
            return value
        }

        return switch value {
        case "icloud", "externaldrive": "☁️"
        case "shippingbox": "📦"
        case "sparkles": "✨"
        case "play.tv": "🎬"
        case "music.note": "🎵"
        case "creditcard": "💳"
        case "book": "📚"
        case "gamecontroller": "🎮"
        case "checkmark.circle", "checkmark.seal": "✅"
        case "calendar", "calendar.circle", "calendar.badge.clock": "📅"
        case "chart.pie", "chart.line.uptrend.xyaxis": "📊"
        case "gearshape": "⚙️"
        case "list.bullet.rectangle": "📋"
        case "square.grid.2x2": "🔷"
        case "archivebox": "🗄️"
        case "trash": "🗑️"
        case "pencil": "✏️"
        default: "💠"
        }
    }

    static func migrateLegacyValue(_ value: String) -> String {
        emoji(for: value)
    }
}

struct EmojiBadge: View {
    let value: String
    var size: CGFloat = 42
    var background: Color = .accentColor

    var body: some View {
        Text(EmojiIcon.emoji(for: value))
            .font(.system(size: size * 0.48))
            .frame(width: size, height: size)
            .background(background.gradient, in: Circle())
            .shadow(color: background.opacity(0.25), radius: 10, y: 5)
            .accessibilityLabel(EmojiIcon.emoji(for: value))
    }
}

private extension String {
    var containsEmoji: Bool {
        unicodeScalars.contains { scalar in
            scalar.properties.isEmojiPresentation || scalar.properties.isEmoji
        }
    }
}
