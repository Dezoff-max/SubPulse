import Foundation

struct AppStoreImportResult: Identifiable, Equatable {
    var id = UUID()
    var name: String
    var amount: Double
    var currency: String
    var billingPeriod: BillingPeriod
    var nextPaymentDate: Date?
    var sourceText: String
    var isSelected = true
}
