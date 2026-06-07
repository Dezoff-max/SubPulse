import Foundation
import SwiftData

@Model
final class PaymentMethod: Identifiable {
    @Attribute(.unique) var id: UUID
    var name: String
    var type: String
    var last4: String?
    var colorHex: String

    init(
        id: UUID = UUID(),
        name: String,
        type: String,
        last4: String? = nil,
        colorHex: String
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.last4 = last4
        self.colorHex = colorHex
    }
}
