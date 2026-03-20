import XCTest
@testable import FinansFlow

final class FinansFlowTests: XCTestCase {
    func testWorkspaceDataLoaderReloadsAllSourcesWithSameWorkspaceId() async {
        let workspaceId = UUID()
        let recorder = CallRecorder()
        let loader = WorkspaceDataLoader(
            loadCategories: { await recorder.record("categories:\($0.uuidString)") },
            loadTransactions: { await recorder.record("transactions:\($0.uuidString)") },
            loadInvestments: { await recorder.record("investments:\($0.uuidString)") },
            loadPassiveIncomes: { await recorder.record("passive:\($0.uuidString)") },
            loadLiabilities: { await recorder.record("liabilities:\($0.uuidString)") },
            loadAssets: { await recorder.record("assets:\($0.uuidString)") },
            loadSnapshots: { await recorder.record("snapshots:\($0.uuidString)") }
        )

        await loader.reload(workspaceId: workspaceId)

        let calls = await recorder.calls
        XCTAssertEqual(calls, [
            "categories:\(workspaceId.uuidString)",
            "transactions:\(workspaceId.uuidString)",
            "investments:\(workspaceId.uuidString)",
            "passive:\(workspaceId.uuidString)",
            "liabilities:\(workspaceId.uuidString)",
            "assets:\(workspaceId.uuidString)",
            "snapshots:\(workspaceId.uuidString)"
        ])
    }

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

    func testFilteredTransactionsSupportsCategoryVisibilityAndDateRange() {
        let workspaceId = UUID()
        let categoryId = UUID()
        let secondCategoryId = UUID()
        let userId = UUID()
        let viewModel = TransactionViewModel()
        viewModel.transactions = [
            Transaction(
                id: UUID(),
                workspaceId: workspaceId,
                userId: userId,
                type: .expense,
                categoryId: categoryId,
                amount: 100,
                currency: "TRY",
                date: Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 10))!,
                description: "Market",
                paymentMethod: "Nakit",
                visibilityScope: .shared,
                isRecurring: false,
                recurrenceInterval: nil,
                tags: nil,
                createdAt: nil,
                updatedAt: nil
            ),
            Transaction(
                id: UUID(),
                workspaceId: workspaceId,
                userId: userId,
                type: .expense,
                categoryId: secondCategoryId,
                amount: 250,
                currency: "TRY",
                date: Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 15))!,
                description: "Kira",
                paymentMethod: "Havale/EFT",
                visibilityScope: .personal,
                isRecurring: false,
                recurrenceInterval: nil,
                tags: nil,
                createdAt: nil,
                updatedAt: nil
            )
        ]

        let filtered = viewModel.filteredTransactions(
            type: .expense,
            categoryId: categoryId,
            visibilityScope: .shared,
            startDate: Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 1))!,
            endDate: Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 12))!
        )

        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.description, "Market")
    }

    func testTransactionFilterSupportScopesCategoriesBySelectedType() {
        let incomeCategory = Category(
            id: UUID(),
            workspaceId: UUID(),
            name: "Maas",
            type: .income,
            parentId: nil,
            color: "#00FF00",
            icon: "banknote",
            monthlyBudget: nil,
            isDefault: false,
            createdAt: nil
        )
        let expenseCategory = Category(
            id: UUID(),
            workspaceId: UUID(),
            name: "Market",
            type: .expense,
            parentId: nil,
            color: "#FF0000",
            icon: "cart",
            monthlyBudget: nil,
            isDefault: false,
            createdAt: nil
        )

        let filtered = TransactionFilterSupport.availableCategories(
            categories: [incomeCategory, expenseCategory],
            selectedType: TransactionType.income
        )

        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.map { $0.id }, [incomeCategory.id])
    }

    func testTransactionFilterSupportDetectsFilteredEmptyState() {
        XCTAssertTrue(
            TransactionFilterSupport.isFilterResultEmpty(
                hasTransactions: true,
                hasActiveFilters: true,
                searchText: ""
            )
        )
        XCTAssertTrue(
            TransactionFilterSupport.isFilterResultEmpty(
                hasTransactions: true,
                hasActiveFilters: false,
                searchText: "market"
            )
        )
        XCTAssertFalse(
            TransactionFilterSupport.isFilterResultEmpty(
                hasTransactions: false,
                hasActiveFilters: true,
                searchText: ""
            )
        )
    }

    func testTransactionFilterSupportClearsMissingCategorySelection() {
        let categoryId = UUID()
        let keptSelection = TransactionFilterSupport.normalizedCategorySelection(
            selectedCategoryId: categoryId,
            categories: [
                Category(
                    id: categoryId,
                    workspaceId: UUID(),
                    name: "Market",
                    type: .expense,
                    parentId: nil,
                    color: "#FF0000",
                    icon: "cart",
                    monthlyBudget: nil,
                    isDefault: false,
                    createdAt: nil
                )
            ],
            selectedType: .expense,
            resetIfMissing: false
        )
        let clearedSelection = TransactionFilterSupport.normalizedCategorySelection(
            selectedCategoryId: categoryId,
            categories: [],
            selectedType: .expense,
            resetIfMissing: true
        )

        XCTAssertEqual(keptSelection, categoryId)
        XCTAssertNil(clearedSelection)
    }
}

private actor CallRecorder {
    private(set) var calls: [String] = []

    func record(_ value: String) {
        calls.append(value)
    }
}
