import Foundation

struct DashboardNetWorthSummary: Equatable {
    let totalAssets: Double
    let totalLiabilities: Double
    let netWorth: Double
    let deltaAmount: Double?

    var hasAnyData: Bool {
        totalAssets > 0 || totalLiabilities > 0 || deltaAmount != nil
    }

    var isPositive: Bool {
        netWorth >= 0
    }

    var deltaText: String? {
        guard let deltaAmount else { return nil }
        if deltaAmount == 0 {
            return String(localized: "Son snapshot ile aynı seviyede")
        }

        let prefix = deltaAmount > 0
            ? String(localized: "Son snapshot'a göre artış:")
            : String(localized: "Son snapshot'a göre düşüş:")
        return "\(prefix) \(deltaAmount.formatted())"
    }
}

enum DashboardMetrics {
    static func netWorthSummary(
        assets: [Asset],
        liabilities: [Liability],
        snapshots: [NetWorthSnapshot]
    ) -> DashboardNetWorthSummary {
        let totalAssets = assets.reduce(0) { $0 + $1.value }
        let totalLiabilities = liabilities.reduce(0) { $0 + $1.remainingAmount }
        let netWorth = totalAssets - totalLiabilities
        let latestSnapshot = snapshots.max(by: { $0.date < $1.date })
        let deltaAmount = latestSnapshot.map { netWorth - $0.netWorth }

        return DashboardNetWorthSummary(
            totalAssets: totalAssets,
            totalLiabilities: totalLiabilities,
            netWorth: netWorth,
            deltaAmount: deltaAmount
        )
    }
}
