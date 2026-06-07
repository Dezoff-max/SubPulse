import Foundation

struct PaymentOccurrence: Identifiable {
    let id = UUID()
    let subscription: Subscription
    let date: Date

    var amount: Double { subscription.amount }
    var currency: String { subscription.currency }
}
