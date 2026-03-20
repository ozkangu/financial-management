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

    func testDashboardPassiveIncomeSummaryCalculatesMonthlyAmountRatioAndNextPayment() {
        let workspaceId = UUID()
        let userId = UUID()
        let passiveIncomes = [
            PassiveIncome(
                id: UUID(),
                workspaceId: workspaceId,
                userId: userId,
                investmentId: nil,
                type: .dividend,
                amount: 1_200,
                currency: "TRY",
                frequency: .monthly,
                nextPaymentDate: Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 25)),
                description: "Fon Temettusu",
                createdAt: nil
            ),
            PassiveIncome(
                id: UUID(),
                workspaceId: workspaceId,
                userId: userId,
                investmentId: nil,
                type: .rent,
                amount: 12_000,
                currency: "TRY",
                frequency: .yearly,
                nextPaymentDate: Calendar.current.date(from: DateComponents(year: 2026, month: 4, day: 5)),
                description: "Depo Kirasi",
                createdAt: nil
            )
        ]

        let summary = DashboardMetrics.passiveIncomeSummary(
            passiveIncomes: passiveIncomes,
            totalMonthlyIncome: 10_000
        )

        XCTAssertEqual(summary.monthlyAmount, 2_200, accuracy: 0.001)
        XCTAssertEqual(summary.ratio, 22, accuracy: 0.001)
        XCTAssertEqual(summary.nextPaymentDescription, "Fon Temettusu")
        XCTAssertEqual(
            summary.nextPaymentDate,
            Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 25))
        )
        XCTAssertTrue(summary.hasAnyData)
    }

    func testDashboardPassiveIncomeSummaryShowsEmptyStateWithoutRecords() {
        let summary = DashboardMetrics.passiveIncomeSummary(
            passiveIncomes: [],
            totalMonthlyIncome: 8_000
        )

        XCTAssertEqual(summary.monthlyAmount, 0)
        XCTAssertEqual(summary.ratio, 0)
        XCTAssertNil(summary.nextPaymentDate)
        XCTAssertFalse(summary.hasAnyData)
    }

    func testDashboardInsightsGenerateTopExpenseMonthlyChangeAndDebtPressure() {
        let calendar = Calendar.current
        let now = calendar.date(from: DateComponents(year: 2026, month: 3, day: 20))!
        let foodCategoryId = UUID()
        let rentCategoryId = UUID()
        let categories = [
            Category(
                id: foodCategoryId,
                workspaceId: UUID(),
                name: "Market",
                type: .expense,
                parentId: nil,
                color: "#FF0000",
                icon: "cart",
                monthlyBudget: nil,
                isDefault: false,
                createdAt: nil
            ),
            Category(
                id: rentCategoryId,
                workspaceId: UUID(),
                name: "Kira",
                type: .expense,
                parentId: nil,
                color: "#00FF00",
                icon: "house",
                monthlyBudget: nil,
                isDefault: false,
                createdAt: nil
            )
        ]
        let transactions = [
            Transaction(
                id: UUID(),
                workspaceId: UUID(),
                userId: UUID(),
                type: .income,
                categoryId: nil,
                amount: 10_000,
                currency: "TRY",
                date: calendar.date(from: DateComponents(year: 2026, month: 3, day: 5))!,
                description: "Maas",
                paymentMethod: nil,
                visibilityScope: .personal,
                isRecurring: false,
                recurrenceInterval: nil,
                tags: nil,
                createdAt: nil,
                updatedAt: nil
            ),
            Transaction(
                id: UUID(),
                workspaceId: UUID(),
                userId: UUID(),
                type: .expense,
                categoryId: foodCategoryId,
                amount: 2_500,
                currency: "TRY",
                date: calendar.date(from: DateComponents(year: 2026, month: 3, day: 7))!,
                description: "Market",
                paymentMethod: nil,
                visibilityScope: .shared,
                isRecurring: false,
                recurrenceInterval: nil,
                tags: nil,
                createdAt: nil,
                updatedAt: nil
            ),
            Transaction(
                id: UUID(),
                workspaceId: UUID(),
                userId: UUID(),
                type: .expense,
                categoryId: rentCategoryId,
                amount: 1_500,
                currency: "TRY",
                date: calendar.date(from: DateComponents(year: 2026, month: 3, day: 2))!,
                description: "Kira",
                paymentMethod: nil,
                visibilityScope: .shared,
                isRecurring: false,
                recurrenceInterval: nil,
                tags: nil,
                createdAt: nil,
                updatedAt: nil
            ),
            Transaction(
                id: UUID(),
                workspaceId: UUID(),
                userId: UUID(),
                type: .income,
                categoryId: nil,
                amount: 8_000,
                currency: "TRY",
                date: calendar.date(from: DateComponents(year: 2026, month: 2, day: 5))!,
                description: "Subat Maas",
                paymentMethod: nil,
                visibilityScope: .personal,
                isRecurring: false,
                recurrenceInterval: nil,
                tags: nil,
                createdAt: nil,
                updatedAt: nil
            ),
            Transaction(
                id: UUID(),
                workspaceId: UUID(),
                userId: UUID(),
                type: .expense,
                categoryId: rentCategoryId,
                amount: 2_000,
                currency: "TRY",
                date: calendar.date(from: DateComponents(year: 2026, month: 2, day: 11))!,
                description: "Subat Kira",
                paymentMethod: nil,
                visibilityScope: .shared,
                isRecurring: false,
                recurrenceInterval: nil,
                tags: nil,
                createdAt: nil,
                updatedAt: nil
            )
        ]
        let liabilities = [
            Liability(
                id: UUID(),
                workspaceId: UUID(),
                userId: UUID(),
                name: "Kredi Karti",
                type: .creditCard,
                totalAmount: 50_000,
                remainingAmount: 30_000,
                interestRate: nil,
                monthlyPayment: 4_500,
                currency: "TRY",
                dueDate: nil,
                notes: nil,
                createdAt: nil,
                updatedAt: nil
            )
        ]

        let insights = DashboardMetrics.insights(
            transactions: transactions,
            categories: categories,
            liabilities: liabilities,
            referenceDate: now
        )

        XCTAssertEqual(insights.count, 3)
        XCTAssertTrue(insights.contains(where: { $0.title == "En Yuksek Gider" && $0.message.contains("Market") }))
        XCTAssertTrue(insights.contains(where: { $0.title == "Aylik Degisim" && $0.message.contains("gelir") }))
        XCTAssertTrue(insights.contains(where: { $0.title == "Borc Baskisi" }))
    }

    func testDashboardInsightsProvideFallbacksWithoutData() {
        let insights = DashboardMetrics.insights(
            transactions: [],
            categories: [],
            liabilities: [],
            referenceDate: Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 20))!
        )

        XCTAssertEqual(insights.count, 3)
        XCTAssertTrue(insights.contains(where: { $0.message.contains("henuz olusmadi") }))
        XCTAssertTrue(insights.contains(where: { $0.message.contains("henuz hesaplanamiyor") }))
        XCTAssertTrue(insights.contains(where: { $0.message.contains("basa bas") }))
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

    func testCSVExportBuilderIncludesWorkspaceCategoryAndTransactionFields() {
        let workspace = Workspace(
            id: UUID(),
            name: "Aile Butcesi",
            ownerId: UUID(),
            createdAt: nil
        )
        let categoryId = UUID()
        let category = Category(
            id: categoryId,
            workspaceId: workspace.id,
            name: "Market",
            type: .expense,
            parentId: nil,
            color: "#FF0000",
            icon: "cart",
            monthlyBudget: nil,
            isDefault: false,
            createdAt: nil
        )
        let transaction = Transaction(
            id: UUID(),
            workspaceId: workspace.id,
            userId: UUID(),
            type: .expense,
            categoryId: categoryId,
            amount: 450.75,
            currency: "TRY",
            date: Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 20))!,
            description: "Haftalik market",
            paymentMethod: nil,
            visibilityScope: .shared,
            isRecurring: false,
            recurrenceInterval: nil,
            tags: nil,
            createdAt: nil,
            updatedAt: nil
        )

        let csv = CSVExportBuilder.transactionsCSV(
            workspace: workspace,
            transactions: [transaction],
            categories: [category]
        )

        XCTAssertTrue(csv.contains("\"Workspace\",\"Tarih\",\"Tur\",\"Tutar\",\"Para Birimi\",\"Kategori\",\"Kapsam\",\"Aciklama\""))
        XCTAssertTrue(csv.contains("\"Aile Butcesi\""))
        XCTAssertTrue(csv.contains("\"Market\""))
        XCTAssertTrue(csv.contains("\"Ortak\""))
        XCTAssertTrue(csv.contains("\"Haftalik market\""))
    }

    func testCSVExportBuilderBuildsWorkspaceAwareFilename() {
        let workspace = Workspace(
            id: UUID(),
            name: "Benim Alanim",
            ownerId: UUID(),
            createdAt: nil
        )

        XCTAssertEqual(
            CSVExportBuilder.filename(for: workspace),
            "finansflow-benim-alanim-transactions.csv"
        )
        XCTAssertEqual(
            CSVExportBuilder.filename(for: nil),
            "finansflow-transactions.csv"
        )
    }

    func testCSVExportBuilderEscapesQuotesCommasAndNewlines() {
        let workspace = Workspace(
            id: UUID(),
            name: "Is / Ev: Butcesi",
            ownerId: UUID(),
            createdAt: nil
        )
        let categoryId = UUID()
        let category = Category(
            id: categoryId,
            workspaceId: workspace.id,
            name: "Market, Manav",
            type: .expense,
            parentId: nil,
            color: "#00AA00",
            icon: "cart",
            monthlyBudget: nil,
            isDefault: false,
            createdAt: nil
        )
        let transaction = Transaction(
            id: UUID(),
            workspaceId: workspace.id,
            userId: UUID(),
            type: .expense,
            categoryId: categoryId,
            amount: 99.9,
            currency: "TRY",
            date: Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 21))!,
            description: "Sebze \"indirim\"\n2 kalem",
            paymentMethod: nil,
            visibilityScope: .personal,
            isRecurring: false,
            recurrenceInterval: nil,
            tags: nil,
            createdAt: nil,
            updatedAt: nil
        )

        let csv = CSVExportBuilder.transactionsCSV(
            workspace: workspace,
            transactions: [transaction],
            categories: [category]
        )

        XCTAssertTrue(csv.contains("\"Market, Manav\""))
        XCTAssertTrue(csv.contains("\"Sebze \"\"indirim\"\"\n2 kalem\""))
        XCTAssertEqual(
            CSVExportBuilder.filename(for: workspace),
            "finansflow-is-ev-butcesi-transactions.csv"
        )
    }
}

private actor CallRecorder {
    private(set) var calls: [String] = []

    func record(_ value: String) {
        calls.append(value)
    }
}
