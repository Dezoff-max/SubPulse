import Foundation
import SwiftData

@Model
final class Category: Identifiable {
    @Attribute(.unique) var id: UUID
    var name: String
    var colorHex: String
    var iconName: String

    init(
        id: UUID = UUID(),
        name: String,
        colorHex: String,
        iconName: String
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.iconName = iconName
    }
}
