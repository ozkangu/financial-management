import Foundation
import SwiftData

@Model
final class NetWorthSnapshot {
    var id: UUID
    var date: Date
    var totalAssets: Double
    var totalLiabilities: Double
    var netWorth: Double
    var createdAt: Date

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        totalAssets: Double,
        totalLiabilities: Double,
        netWorth: Double,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.date = date
        self.totalAssets = totalAssets
        self.totalLiabilities = totalLiabilities
        self.netWorth = netWorth
        self.createdAt = createdAt
    }
}
