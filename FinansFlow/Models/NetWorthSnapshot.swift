import Foundation

struct NetWorthSnapshot: Codable, Identifiable, Sendable {
    let id: UUID
    let workspaceId: UUID
    let date: Date
    let totalAssets: Double
    let totalLiabilities: Double
    let netWorth: Double
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, date
        case workspaceId = "workspace_id"
        case totalAssets = "total_assets"
        case totalLiabilities = "total_liabilities"
        case netWorth = "net_worth"
        case createdAt = "created_at"
    }
}
