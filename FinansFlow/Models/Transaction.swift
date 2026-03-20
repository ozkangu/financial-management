import Foundation

enum TransactionType: String, Codable, Sendable, CaseIterable {
    case income
    case expense
}

enum VisibilityScope: String, Codable, Sendable, CaseIterable {
    case personal
    case shared
}

enum RecurrenceInterval: String, Codable, Sendable, CaseIterable {
    case weekly
    case monthly
    case yearly
}

struct Transaction: Codable, Identifiable, Sendable {
    let id: UUID
    let workspaceId: UUID
    let userId: UUID
    var type: TransactionType
    var categoryId: UUID?
    var amount: Double
    var currency: String
    var date: Date
    var description: String?
    var paymentMethod: String?
    var visibilityScope: VisibilityScope
    var isRecurring: Bool
    var recurrenceInterval: RecurrenceInterval?
    var tags: [String]?
    let createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, type, amount, currency, date, description, tags
        case workspaceId = "workspace_id"
        case userId = "user_id"
        case categoryId = "category_id"
        case paymentMethod = "payment_method"
        case visibilityScope = "visibility_scope"
        case isRecurring = "is_recurring"
        case recurrenceInterval = "recurrence_interval"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
