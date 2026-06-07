import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case english
    case russian

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: "System"
        case .english: "English"
        case .russian: "Русский"
        }
    }

    func localizedTitle(language rawLanguage: String) -> String {
        let language = AppLanguage(rawValue: rawLanguage) ?? .system
        guard language.resolvedCode == "ru" else { return title }
        return switch self {
        case .system: "Как в системе"
        case .english: "English"
        case .russian: "Русский"
        }
    }

    var resolvedCode: String {
        switch self {
        case .english:
            return "en"
        case .russian:
            return "ru"
        case .system:
            let preferred = Locale.preferredLanguages.first?.lowercased() ?? "en"
            return preferred.hasPrefix("ru") ? "ru" : "en"
        }
    }

    var locale: Locale {
        Locale(identifier: resolvedCode)
    }
}

enum AppAppearance: String, CaseIterable, Identifiable {
    case softNeumorphic
    case softNeumorphicDark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .softNeumorphic: "Soft Neumorphic"
        case .softNeumorphicDark: "Soft Neumorphic Dark"
        }
    }

    func localizedTitle(language rawLanguage: String) -> String {
        let language = AppLanguage(rawValue: rawLanguage) ?? .system
        guard language.resolvedCode == "ru" else { return title }
        return switch self {
        case .softNeumorphic: "Soft Neumorphic"
        case .softNeumorphicDark: "Soft Neumorphic Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .softNeumorphic: .light
        case .softNeumorphicDark: .dark
        }
    }

    var isSoftNeumorphic: Bool {
        self == .softNeumorphic || self == .softNeumorphicDark
    }

    static func normalizedRawValue(_ rawValue: String) -> String {
        AppAppearance(rawValue: rawValue)?.rawValue ?? AppAppearance.softNeumorphic.rawValue
    }
}

enum L10n {
    static func text(_ key: String, language rawLanguage: String) -> String {
        let language = AppLanguage(rawValue: rawLanguage) ?? .system
        let isRussian = language.resolvedCode == "ru"
        return isRussian ? russian[key, default: english[key, default: key]] : english[key, default: key]
    }

    static func calendar(language rawLanguage: String) -> Calendar {
        let language = AppLanguage(rawValue: rawLanguage) ?? .system
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = language.resolvedCode == "ru" ? Locale(identifier: "ru_RU") : language.locale
        calendar.firstWeekday = language.resolvedCode == "ru" ? 2 : Calendar.current.firstWeekday
        return calendar
    }

    static func shortWeekdaySymbols(language rawLanguage: String) -> [String] {
        let calendar = calendar(language: rawLanguage)
        let formatter = DateFormatter()
        formatter.locale = calendar.locale
        var symbols = formatter.shortStandaloneWeekdaySymbols ?? formatter.shortWeekdaySymbols ?? Calendar.current.shortWeekdaySymbols
        let shift = max(calendar.firstWeekday - 1, 0)
        if shift > 0 {
            symbols = Array(symbols.dropFirst(shift)) + Array(symbols.prefix(shift))
        }
        return symbols.map { $0.replacingOccurrences(of: ".", with: "").capitalized }
    }

    static func shortDate(_ date: Date, language rawLanguage: String) -> String {
        let language = AppLanguage(rawValue: rawLanguage) ?? .system
        let formatter = DateFormatter()
        formatter.locale = language.resolvedCode == "ru" ? Locale(identifier: "ru_RU") : language.locale
        formatter.dateFormat = language.resolvedCode == "ru" ? "dd.MM.yyyy" : "MMM d, yyyy"
        return formatter.string(from: date)
    }

    static func monthYear(_ date: Date, language rawLanguage: String) -> String {
        let language = AppLanguage(rawValue: rawLanguage) ?? .system
        let formatter = DateFormatter()
        formatter.locale = language.resolvedCode == "ru" ? Locale(identifier: "ru_RU") : language.locale
        formatter.dateFormat = "LLLL yyyy"
        let value = formatter.string(from: date)
        return language.resolvedCode == "ru" ? value.capitalized : value
    }

    static func weekdayDayMonth(_ date: Date, language rawLanguage: String) -> String {
        let language = AppLanguage(rawValue: rawLanguage) ?? .system
        let formatter = DateFormatter()
        formatter.locale = language.resolvedCode == "ru" ? Locale(identifier: "ru_RU") : language.locale
        formatter.dateFormat = language.resolvedCode == "ru" ? "EEEE, d MMMM" : "EEEE, MMM d"
        return formatter.string(from: date).capitalized
    }

    static func editorDate(_ date: Date, language rawLanguage: String) -> String {
        let language = AppLanguage(rawValue: rawLanguage) ?? .system
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = language.resolvedCode == "ru" ? "dd.MM.yyyy" : "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    static func categoryName(_ name: String, language rawLanguage: String) -> String {
        let language = AppLanguage(rawValue: rawLanguage) ?? .system
        guard language.resolvedCode == "ru" else { return name }
        return russianCategoryNames[name, default: name]
    }

    static func paymentMethodName(_ name: String, language rawLanguage: String) -> String {
        let language = AppLanguage(rawValue: rawLanguage) ?? .system
        let key = normalizedPaymentMethodName(name)
        if language.resolvedCode == "ru" {
            return russianPaymentMethodNames[key, default: name]
        }
        return englishPaymentMethodNames[key, default: name]
    }

    private static func normalizedPaymentMethodName(_ name: String) -> String {
        name
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
    }
}

enum AppAccent: String, CaseIterable, Identifiable {
    case pulseBlue
    case mint
    case violet
    case coral
    case graphite

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pulseBlue: "Pulse Blue"
        case .mint: "Mint"
        case .violet: "Violet"
        case .coral: "Coral"
        case .graphite: "Graphite"
        }
    }

    func localizedTitle(language rawLanguage: String) -> String {
        let language = AppLanguage(rawValue: rawLanguage) ?? .system
        guard language.resolvedCode == "ru" else { return title }
        return switch self {
        case .pulseBlue: "Синий Pulse"
        case .mint: "Мятный"
        case .violet: "Фиолетовый"
        case .coral: "Коралловый"
        case .graphite: "Графит"
        }
    }

    var color: Color {
        switch self {
        case .pulseBlue: Color(red: 0.05, green: 0.45, blue: 1.0)
        case .mint: Color(red: 0.0, green: 0.72, blue: 0.56)
        case .violet: Color(red: 0.54, green: 0.32, blue: 1.0)
        case .coral: Color(red: 1.0, green: 0.36, blue: 0.32)
        case .graphite: Color(red: 0.32, green: 0.34, blue: 0.38)
        }
    }
}
