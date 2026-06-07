enum SubscriptionNameNormalizer {
    static func normalized(_ name: String) -> String {
        var normalized = name
            .lowercased()
            .replacingOccurrences(of: "plus", with: "")
            .replacingOccurrences(of: "premium", with: "")
            .replacingOccurrences(of: "subscription", with: "")
            .replacingOccurrences(of: "подписка", with: "")
            .replacingOccurrences(of: "+", with: "")
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: " ", with: "")

        if normalized.contains("chatgpt") || normalized.contains("openai") {
            normalized = "chatgpt"
        } else if normalized.contains("telegram") {
            normalized = "telegram"
        } else if normalized.contains("icloud") {
            normalized = "icloud"
        }

        return normalized
    }
}
