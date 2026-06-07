import AppKit
import SwiftUI

extension Color {
    init(hex: String) {
        let value = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var integer: UInt64 = 0
        Scanner(string: value).scanHexInt64(&integer)

        let red: Double
        let green: Double
        let blue: Double

        switch value.count {
        case 6:
            red = Double((integer >> 16) & 0xff) / 255
            green = Double((integer >> 8) & 0xff) / 255
            blue = Double(integer & 0xff) / 255
        default:
            red = 0.4
            green = 0.5
            blue = 0.8
        }

        self.init(red: red, green: green, blue: blue)
    }

    init(lightHex: String, darkHex: String) {
        self.init(nsColor: NSColor(name: nil) { appearance in
            let bestMatch = appearance.bestMatch(from: [.darkAqua, .aqua])
            return NSColor(hex: bestMatch == .darkAqua ? darkHex : lightHex)
        })
    }
}

private extension NSColor {
    convenience init(hex: String) {
        let value = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var integer: UInt64 = 0
        Scanner(string: value).scanHexInt64(&integer)

        let red: CGFloat
        let green: CGFloat
        let blue: CGFloat

        switch value.count {
        case 6:
            red = CGFloat((integer >> 16) & 0xff) / 255
            green = CGFloat((integer >> 8) & 0xff) / 255
            blue = CGFloat(integer & 0xff) / 255
        default:
            red = 0.4
            green = 0.5
            blue = 0.8
        }

        self.init(red: red, green: green, blue: blue, alpha: 1)
    }
}
