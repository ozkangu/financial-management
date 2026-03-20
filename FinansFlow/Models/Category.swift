import Foundation
import SwiftData

enum CategoryType: String, Codable, Sendable, CaseIterable, Hashable {
    case income
    case expense
}

@Model
final class Category {
    var id: UUID
    var name: String
    var type: CategoryType
    @Relationship(inverse: \Category.parent)
    var subcategories: [Category]
    var parent: Category?
    var color: String
    var icon: String
    var monthlyBudget: Double?
    var isDefault: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        type: CategoryType,
        parent: Category? = nil,
        color: String = "#007AFF",
        icon: String = "folder.fill",
        monthlyBudget: Double? = nil,
        isDefault: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.parent = parent
        self.subcategories = []
        self.color = color
        self.icon = icon
        self.monthlyBudget = monthlyBudget
        self.isDefault = isDefault
        self.createdAt = createdAt
    }
}
