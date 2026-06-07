import Foundation

enum BundleInfo {
    static var shortVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.2.0"
    }

    static var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
    }

    static var displayVersion: String {
        guard !buildNumber.isEmpty else { return shortVersion }
        return "\(shortVersion) (\(buildNumber))"
    }
}
