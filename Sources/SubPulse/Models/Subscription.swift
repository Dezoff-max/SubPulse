import Foundation
import SwiftData

@Model
final class Subscription: Identifiable {
    @Attribute(.unique) var id: UUID
    var name: String
    var amount: Double
    var currency: String
    var billingPeriodRaw: String
    var nextPaymentDate: Date
    var trialStartDate: Date?
    var trialEndDate: Date?
    var category: Category?
    var paymentMethod: PaymentMethod?
    var iconName: String
    var notes: String
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date

    var billingPeriod: BillingPeriod {
        get { BillingPeriod(rawValue: billingPeriodRaw) ?? .monthly }
        set { billingPeriodRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        name: String,
        amount: Double,
        currency: String = "USD",
        billingPeriod: BillingPeriod,
        nextPaymentDate: Date,
        trialStartDate: Date? = nil,
        trialEndDate: Date? = nil,
        category: Category? = nil,
        paymentMethod: PaymentMethod? = nil,
        iconName: String = "creditcard",
        notes: String = "",
        isActive: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.currency = currency
        self.billingPeriodRaw = billingPeriod.rawValue
        self.nextPaymentDate = nextPaymentDate
        self.trialStartDate = trialStartDate
        self.trialEndDate = trialEndDate
        self.category = category
        self.paymentMethod = paymentMethod
        self.iconName = iconName
        self.notes = notes
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    func billableNextPaymentDate(calendar: Calendar = .current) -> Date {
        guard let trialEndDate else {
            return nextPaymentDate
        }

        let paymentDay = calendar.startOfDay(for: nextPaymentDate)
        let trialEndDay = calendar.startOfDay(for: trialEndDate)
        let firstPaidDay = calendar.date(byAdding: .day, value: 1, to: trialEndDay) ?? trialEndDay
        return paymentDay < firstPaidDay ? firstPaidDay : paymentDay
    }
}
