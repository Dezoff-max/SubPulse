import AppKit
import Foundation
import SwiftData
import UniformTypeIdentifiers

@MainActor
enum DataBackupService {
    static func exportBackup(
        subscriptions: [Subscription],
        categories: [Category],
        paymentMethods: [PaymentMethod],
        language: String
    ) -> String? {
        guard let url = chooseExportURL() else { return nil }

        do {
            try backupData(
                subscriptions: subscriptions,
                categories: categories,
                paymentMethods: paymentMethods
            )
            .write(to: url, options: .atomic)
            return String(format: L10n.text("backupExportedFormat", language: language), url.lastPathComponent)
        } catch {
            return L10n.text("backupExportFailed", language: language)
        }
    }

    static func restoreBackup(
        in context: ModelContext,
        existingSubscriptions: [Subscription],
        existingCategories: [Category],
        existingPaymentMethods: [PaymentMethod],
        language: String
    ) -> BackupRestoreResult? {
        guard let url = chooseImportURL() else { return nil }

        do {
            let data = try Data(contentsOf: url)
            let snapshot = try decodeBackup(data)
            let restoredSubscriptions = restore(
                snapshot: snapshot,
                in: context,
                existingSubscriptions: existingSubscriptions,
                existingCategories: existingCategories,
                existingPaymentMethods: existingPaymentMethods
            )
            try context.save()
            let message = String(
                format: L10n.text("backupRestoredFormat", language: language),
                restoredSubscriptions.count
            )
            return BackupRestoreResult(message: message, subscriptions: restoredSubscriptions)
        } catch {
            return BackupRestoreResult(
                message: L10n.text("backupRestoreFailed", language: language),
                subscriptions: []
            )
        }
    }

    static func backupData(
        subscriptions: [Subscription],
        categories: [Category],
        paymentMethods: [PaymentMethod]
    ) throws -> Data {
        let snapshot = SubPulseBackupSnapshot(
            appVersion: BundleInfo.shortVersion,
            buildNumber: BundleInfo.buildNumber,
            exportedAt: Date(),
            categories: categories.map(BackupCategory.init),
            paymentMethods: paymentMethods.map(BackupPaymentMethod.init),
            subscriptions: subscriptions.map(BackupSubscription.init)
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(snapshot)
    }

    static func decodeBackup(_ data: Data) throws -> SubPulseBackupSnapshot {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(SubPulseBackupSnapshot.self, from: data)
    }

    @discardableResult
    static func restore(
        snapshot: SubPulseBackupSnapshot,
        in context: ModelContext,
        existingSubscriptions: [Subscription],
        existingCategories: [Category],
        existingPaymentMethods: [PaymentMethod],
        cancelNotifications: Bool = true
    ) -> [Subscription] {
        replaceData(
            with: snapshot,
            in: context,
            existingSubscriptions: existingSubscriptions,
            existingCategories: existingCategories,
            existingPaymentMethods: existingPaymentMethods,
            cancelNotifications: cancelNotifications
        )
    }

    private static func chooseExportURL() -> URL? {
        let panel = NSSavePanel()
        panel.title = "Export SubPulse Backup"
        panel.nameFieldStringValue = "SubPulse-Backup-\(Self.filenameDate()).json"
        panel.allowedContentTypes = [.json]
        panel.canCreateDirectories = true
        return panel.runModal() == .OK ? panel.url : nil
    }

    private static func chooseImportURL() -> URL? {
        let panel = NSOpenPanel()
        panel.title = "Restore SubPulse Backup"
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        return panel.runModal() == .OK ? panel.url : nil
    }

    private static func filenameDate() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd-HHmm"
        return formatter.string(from: Date())
    }

    private static func replaceData(
        with snapshot: SubPulseBackupSnapshot,
        in context: ModelContext,
        existingSubscriptions: [Subscription],
        existingCategories: [Category],
        existingPaymentMethods: [PaymentMethod],
        cancelNotifications: Bool
    ) -> [Subscription] {
        for subscription in existingSubscriptions {
            if cancelNotifications {
                NotificationService.shared.cancelReminders(for: subscription)
            }
            context.delete(subscription)
        }
        existingCategories.forEach(context.delete)
        existingPaymentMethods.forEach(context.delete)

        var categoriesByID: [UUID: Category] = [:]
        for item in snapshot.categories {
            let category = Category(
                id: item.id,
                name: item.name,
                colorHex: item.colorHex,
                iconName: item.iconName
            )
            categoriesByID[item.id] = category
            context.insert(category)
        }

        var paymentMethodsByID: [UUID: PaymentMethod] = [:]
        for item in snapshot.paymentMethods {
            let method = PaymentMethod(
                id: item.id,
                name: item.name,
                type: item.type,
                last4: item.last4,
                colorHex: item.colorHex
            )
            paymentMethodsByID[item.id] = method
            context.insert(method)
        }

        var restoredSubscriptions: [Subscription] = []
        for item in snapshot.subscriptions {
            let subscription = Subscription(
                id: item.id,
                name: item.name,
                amount: item.amount,
                currency: item.currency,
                billingPeriod: BillingPeriod(rawValue: item.billingPeriodRaw) ?? .monthly,
                nextPaymentDate: item.nextPaymentDate,
                trialStartDate: item.trialStartDate,
                trialEndDate: item.trialEndDate,
                category: item.categoryID.flatMap { categoriesByID[$0] },
                paymentMethod: item.paymentMethodID.flatMap { paymentMethodsByID[$0] },
                iconName: item.iconName,
                notes: item.notes,
                isActive: item.isActive,
                createdAt: item.createdAt,
                updatedAt: item.updatedAt
            )
            restoredSubscriptions.append(subscription)
            context.insert(subscription)
        }

        return restoredSubscriptions
    }
}

struct BackupRestoreResult {
    let message: String
    let subscriptions: [Subscription]
}

struct SubPulseBackupSnapshot: Codable {
    let schemaVersion: Int
    let appVersion: String
    let buildNumber: String
    let exportedAt: Date
    let categories: [BackupCategory]
    let paymentMethods: [BackupPaymentMethod]
    let subscriptions: [BackupSubscription]

    init(
        appVersion: String,
        buildNumber: String,
        exportedAt: Date,
        categories: [BackupCategory],
        paymentMethods: [BackupPaymentMethod],
        subscriptions: [BackupSubscription]
    ) {
        schemaVersion = 1
        self.appVersion = appVersion
        self.buildNumber = buildNumber
        self.exportedAt = exportedAt
        self.categories = categories
        self.paymentMethods = paymentMethods
        self.subscriptions = subscriptions
    }
}

struct BackupCategory: Codable {
    let id: UUID
    let name: String
    let colorHex: String
    let iconName: String

    init(_ category: Category) {
        id = category.id
        name = category.name
        colorHex = category.colorHex
        iconName = category.iconName
    }
}

struct BackupPaymentMethod: Codable {
    let id: UUID
    let name: String
    let type: String
    let last4: String?
    let colorHex: String

    init(_ method: PaymentMethod) {
        id = method.id
        name = method.name
        type = method.type
        last4 = method.last4
        colorHex = method.colorHex
    }
}

struct BackupSubscription: Codable {
    let id: UUID
    let name: String
    let amount: Double
    let currency: String
    let billingPeriodRaw: String
    let nextPaymentDate: Date
    let trialStartDate: Date?
    let trialEndDate: Date?
    let categoryID: UUID?
    let paymentMethodID: UUID?
    let iconName: String
    let notes: String
    let isActive: Bool
    let createdAt: Date
    let updatedAt: Date

    init(_ subscription: Subscription) {
        id = subscription.id
        name = subscription.name
        amount = subscription.amount
        currency = subscription.currency
        billingPeriodRaw = subscription.billingPeriodRaw
        nextPaymentDate = subscription.nextPaymentDate
        trialStartDate = subscription.trialStartDate
        trialEndDate = subscription.trialEndDate
        categoryID = subscription.category?.id
        paymentMethodID = subscription.paymentMethod?.id
        iconName = subscription.iconName
        notes = subscription.notes
        isActive = subscription.isActive
        createdAt = subscription.createdAt
        updatedAt = subscription.updatedAt
    }
}
