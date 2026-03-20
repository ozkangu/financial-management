import Foundation

struct Workspace: Codable, Identifiable, Sendable {
    let id: UUID
    var name: String
    let ownerId: UUID
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, name
        case ownerId = "owner_id"
        case createdAt = "created_at"
    }
}
