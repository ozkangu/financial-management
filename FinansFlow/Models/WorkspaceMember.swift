import Foundation

enum MemberRole: String, Codable, Sendable {
    case owner
    case member
    case viewer
}

enum MemberStatus: String, Codable, Sendable {
    case pending
    case active
}

struct WorkspaceMember: Codable, Identifiable, Sendable {
    let id: UUID
    let workspaceId: UUID
    let userId: UUID
    var role: MemberRole
    var status: MemberStatus
    let invitedAt: Date?
    var acceptedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, role, status
        case workspaceId = "workspace_id"
        case userId = "user_id"
        case invitedAt = "invited_at"
        case acceptedAt = "accepted_at"
    }
}
