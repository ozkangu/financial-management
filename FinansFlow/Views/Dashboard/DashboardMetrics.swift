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

struct DashboardPassiveIncomeSummary: Equatable {
    let monthlyAmount: Double
    let ratio: Double
    let nextPaymentDate: Date?
    let nextPaymentDescription: String?

    var hasAnyData: Bool {
        monthlyAmount > 0 || nextPaymentDate != nil
    }

    var ratioText: String {
        "Oran: \(ratio.percentFormatted)"
    }

    var nextPaymentText: String? {
        guard let nextPaymentDate else { return nil }

        if let nextPaymentDescription, !nextPaymentDescription.isEmpty {
            return "\(nextPaymentDescription) • \(nextPaymentDate.displayString)"
        }

        return "Siradaki odeme: \(nextPaymentDate.displayString)"
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

    static func passiveIncomeSummary(
        passiveIncomes: [PassiveIncome],
        totalMonthlyIncome: Double
    ) -> DashboardPassiveIncomeSummary {
        let monthlyAmount = passiveIncomes.reduce(0) { $0 + $1.monthlyAmount }
        let ratio = totalMonthlyIncome > 0 ? (monthlyAmount / totalMonthlyIncome) * 100 : 0
        let nextIncome = passiveIncomes
            .filter { income in
                guard let nextPaymentDate = income.nextPaymentDate else { return false }
                return nextPaymentDate >= Calendar.current.startOfDay(for: Date())
            }
            .min { lhs, rhs in
                guard let lhsDate = lhs.nextPaymentDate, let rhsDate = rhs.nextPaymentDate else {
                    return false
                }
                return lhsDate < rhsDate
            }

        return DashboardPassiveIncomeSummary(
            monthlyAmount: monthlyAmount,
            ratio: ratio,
            nextPaymentDate: nextIncome?.nextPaymentDate,
            nextPaymentDescription: nextIncome?.description ?? nextIncome?.type.displayName
        )
    }
}
