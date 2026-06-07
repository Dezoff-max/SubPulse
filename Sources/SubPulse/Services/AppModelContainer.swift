import Foundation
import SwiftData

enum AppModelContainer {
    static let shared: ModelContainer = {
        do {
            return try makePersistentContainer()
        } catch {
            fatalError("Failed to create local SwiftData store: \(error)")
        }
    }()

    static var storeURL: URL {
        applicationSupportDirectory.appendingPathComponent("SubPulse.store")
    }

    private static var applicationSupportDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent("SubPulse", isDirectory: true)
    }

    private static func makePersistentContainer() throws -> ModelContainer {
        try FileManager.default.createDirectory(
            at: applicationSupportDirectory,
            withIntermediateDirectories: true
        )
        migrateLegacyDefaultStoreIfNeeded()

        let schema = Schema([
            Subscription.self,
            Category.self,
            PaymentMethod.self
        ])
        let configuration = ModelConfiguration(schema: schema, url: storeURL)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    private static func migrateLegacyDefaultStoreIfNeeded() {
        let fileManager = FileManager.default
        guard !fileManager.fileExists(atPath: storeURL.path) else { return }

        let legacyURL = fileManager
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent("default.store")
        guard fileManager.fileExists(atPath: legacyURL.path) else { return }

        for suffix in ["", "-shm", "-wal"] {
            let source = URL(fileURLWithPath: legacyURL.path + suffix)
            let destination = URL(fileURLWithPath: storeURL.path + suffix)
            guard fileManager.fileExists(atPath: source.path) else { continue }
            try? fileManager.copyItem(at: source, to: destination)
        }
    }
}
