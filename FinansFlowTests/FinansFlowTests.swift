import XCTest
@testable import FinansFlow

final class FinansFlowTests: XCTestCase {
    func testDashboardNetWorthSummaryCalculatesTotalsAndDeltaFromLatestSnapshot() {
        let workspaceId = UUID()
        let userId = UUID()
        let assets = [
            Asset(
                id: UUID(),
                workspaceId: workspaceId,
                userId: userId,
                name: "Nakit",
                type: .cash,
                value: 150_000,
                currency: "TRY",
                notes: nil,
                createdAt: nil,
                updatedAt: nil
            ),
            Asset(
                id: UUID(),
                workspaceId: workspaceId,
                userId: userId,
                name: "Banka",
                type: .bankAccount,
                value: 50_000,
                currency: "TRY",
                notes: nil,
                createdAt: nil,
                updatedAt: nil
            )
        ]
        let liabilities = [
            Liability(
                id: UUID(),
                workspaceId: workspaceId,
                userId: userId,
                name: "Kredi Kartı",
                type: .creditCard,
                totalAmount: 20_000,
                remainingAmount: 12_000,
                interestRate: nil,
                monthlyPayment: nil,
                currency: "TRY",
                dueDate: nil,
                notes: nil,
                createdAt: nil,
                updatedAt: nil
            )
        ]
        let snapshots = [
            NetWorthSnapshot(
                id: UUID(),
                workspaceId: workspaceId,
                date: Calendar.current.date(byAdding: .day, value: -10, to: Date())!,
                totalAssets: 170_000,
                totalLiabilities: 15_000,
                netWorth: 155_000,
                createdAt: nil
            ),
            NetWorthSnapshot(
                id: UUID(),
                workspaceId: workspaceId,
                date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
                totalAssets: 180_000,
                totalLiabilities: 10_000,
                netWorth: 170_000,
                createdAt: nil
            )
        ]

        let summary = DashboardMetrics.netWorthSummary(
            assets: assets,
            liabilities: liabilities,
            snapshots: snapshots
        )

        XCTAssertEqual(summary.totalAssets, 200_000)
        XCTAssertEqual(summary.totalLiabilities, 12_000)
        XCTAssertEqual(summary.netWorth, 188_000)
        XCTAssertEqual(summary.deltaAmount, 18_000)
        XCTAssertTrue(summary.hasAnyData)
        XCTAssertTrue(summary.isPositive)
    }

    func testDashboardNetWorthSummaryShowsSnapshotContextEvenWhenCurrentTotalsAreZero() {
        let workspaceId = UUID()
        let snapshots = [
            NetWorthSnapshot(
                id: UUID(),
                workspaceId: workspaceId,
                date: Date(),
                totalAssets: 0,
                totalLiabilities: 0,
                netWorth: 0,
                createdAt: nil
            )
        ]

        let summary = DashboardMetrics.netWorthSummary(
            assets: [],
            liabilities: [],
            snapshots: snapshots
        )

        XCTAssertEqual(summary.totalAssets, 0)
        XCTAssertEqual(summary.totalLiabilities, 0)
        XCTAssertEqual(summary.netWorth, 0)
        XCTAssertEqual(summary.deltaAmount, 0)
        XCTAssertTrue(summary.hasAnyData)
        XCTAssertEqual(summary.deltaText, "Son snapshot ile aynı seviyede")
    }
}
