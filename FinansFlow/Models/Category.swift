import Foundation

enum CategoryType: String, Codable, Sendable, CaseIterable {
    case income
    case expense
}

struct Category: Codable, Identifiable, Sendable {
    let id: UUID
    let workspaceId: UUID
    var name: String
    var type: CategoryType
    var parentId: UUID?
    var color: String
    var icon: String
    var monthlyBudget: Double?
    var isDefault: Bool
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, name, type, color, icon
        case workspaceId = "workspace_id"
        case parentId = "parent_id"
        case monthlyBudget = "monthly_budget"
        case isDefault = "is_default"
        case createdAt = "created_at"
    }
}
