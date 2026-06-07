import Foundation

struct SubscriptionDraft {
    var name: String = ""
    var amount: Double = 0
    var currency: String = "USD"
    var billingPeriod: BillingPeriod = .monthly
    var nextPaymentDate: Date = Date()
    var trialStartDate: Date?
    var trialEndDate: Date?
    var category: Category?
    var paymentMethod: PaymentMethod?
    var iconName: String = "sparkles"
    var notes: String = ""
    var isActive: Bool = true

    init() {}

    init(subscription: Subscription) {
        name = subscription.name
        amount = subscription.amount
        currency = subscription.currency
        billingPeriod = subscription.billingPeriod
        nextPaymentDate = subscription.nextPaymentDate
        trialStartDate = subscription.trialStartDate
        trialEndDate = subscription.trialEndDate
        category = subscription.category
        paymentMethod = subscription.paymentMethod
        iconName = subscription.iconName
        notes = subscription.notes
        isActive = subscription.isActive
    }
}
