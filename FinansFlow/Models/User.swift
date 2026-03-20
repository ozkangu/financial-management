import Foundation

struct AppUser: Codable, Identifiable, Sendable {
    let id: UUID
    let email: String
    var name: String?
    var avatarUrl: String?
    var preferredCurrency: String
    let createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, email, name
        case avatarUrl = "avatar_url"
        case preferredCurrency = "preferred_currency"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
