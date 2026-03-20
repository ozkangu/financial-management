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

    func testDashboardCategoryBudgetSummariesHighlightExceededAndWarningBudgets() {
        let workspaceId = UUID()
        let foodId = UUID()
        let transportId = UUID()
        let categories = [
            Category(
                id: foodId,
                workspaceId: workspaceId,
                name: "Market",
                type: .expense,
                parentId: nil,
                color: "#FF0000",
                icon: "cart",
                monthlyBudget: 1_000,
                isDefault: false,
                createdAt: nil
            ),
            Category(
                id: transportId,
                workspaceId: workspaceId,
                name: "Ulasim",
                type: .expense,
                parentId: nil,
                color: "#00FF00",
                icon: "car",
                monthlyBudget: 500,
                isDefault: false,
                createdAt: nil
            )
        ]
        let transactions = [
            Transaction(
                id: UUID(),
                workspaceId: workspaceId,
                userId: UUID(),
                type: .expense,
                categoryId: foodId,
                amount: 1_200,
                currency: "TRY",
                date: Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 12))!,
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
                workspaceId: workspaceId,
                userId: UUID(),
                type: .expense,
                categoryId: transportId,
                amount: 420,
                currency: "TRY",
                date: Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 10))!,
                description: "Taksi",
                paymentMethod: nil,
                visibilityScope: .personal,
                isRecurring: false,
                recurrenceInterval: nil,
                tags: nil,
                createdAt: nil,
                updatedAt: nil
            )
        ]

        let summaries = DashboardMetrics.categoryBudgetSummaries(
            categories: categories,
            transactions: transactions,
            referenceDate: Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 20))!
        )

        XCTAssertEqual(summaries.map(\.name), ["Market", "Ulasim"])
        XCTAssertEqual(summaries[0].status, .exceeded)
        XCTAssertEqual(summaries[1].status, .warning)
        XCTAssertEqual(
            DashboardMetrics.topBudgetAlert(
                categories: categories,
                transactions: transactions,
                referenceDate: Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 20))!
            )?.name,
            "Market"
        )
    }

    func testDashboardCategoryBudgetSummariesIncludeSubcategorySpendAndTrackHealthyBudgets() {
        let workspaceId = UUID()
        let parentId = UUID()
        let childId = UUID()
        let categories = [
            Category(
                id: parentId,
                workspaceId: workspaceId,
                name: "Ev",
                type: .expense,
                parentId: nil,
                color: "#111111",
                icon: "house",
                monthlyBudget: 2_000,
                isDefault: false,
                createdAt: nil
            ),
            Category(
                id: childId,
                workspaceId: workspaceId,
                name: "Fatura",
                type: .expense,
                parentId: parentId,
                color: "#222222",
                icon: "bolt",
                monthlyBudget: nil,
                isDefault: false,
                createdAt: nil
            )
        ]
        let transactions = [
            Transaction(
                id: UUID(),
                workspaceId: workspaceId,
                userId: UUID(),
                type: .expense,
                categoryId: childId,
                amount: 600,
                currency: "TRY",
                date: Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 8))!,
                description: "Elektrik",
                paymentMethod: nil,
                visibilityScope: .shared,
                isRecurring: false,
                recurrenceInterval: nil,
                tags: nil,
                createdAt: nil,
                updatedAt: nil
            )
        ]

        let summaries = DashboardMetrics.categoryBudgetSummaries(
            categories: categories,
            transactions: transactions,
            referenceDate: Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 20))!
        )

        XCTAssertEqual(summaries.first?.spent, 600)
        XCTAssertEqual(summaries.first?.status, .onTrack)
        XCTAssertNil(
            DashboardMetrics.topBudgetAlert(
                categories: categories,
                transactions: transactions,
                referenceDate: Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 20))!
            )
        )
    }

    func testDashboardCategoryBudgetSummariesDoNotDoubleCountBudgetedChildren() {
        let workspaceId = UUID()
        let parentId = UUID()
        let childId = UUID()
        let categories = [
            Category(
                id: parentId,
                workspaceId: workspaceId,
                name: "Ev",
                type: .expense,
                parentId: nil,
                color: "#111111",
                icon: "house",
                monthlyBudget: 2_000,
                isDefault: false,
                createdAt: nil
            ),
            Category(
                id: childId,
                workspaceId: workspaceId,
                name: "Fatura",
                type: .expense,
                parentId: parentId,
                color: "#222222",
                icon: "bolt",
                monthlyBudget: 800,
                isDefault: false,
                createdAt: nil
            )
        ]
        let transactions = [
            Transaction(
                id: UUID(),
                workspaceId: workspaceId,
                userId: UUID(),
                type: .expense,
                categoryId: childId,
                amount: 600,
                currency: "TRY",
                date: Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 8))!,
                description: "Elektrik",
                paymentMethod: nil,
                visibilityScope: .shared,
                isRecurring: false,
                recurrenceInterval: nil,
                tags: nil,
                createdAt: nil,
                updatedAt: nil
            )
        ]

        let summaries = DashboardMetrics.categoryBudgetSummaries(
            categories: categories,
            transactions: transactions,
            referenceDate: Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 20))!
        )

        XCTAssertEqual(summaries.first(where: { $0.id == parentId })?.spent, 0)
        XCTAssertEqual(summaries.first(where: { $0.id == childId })?.spent, 600)
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

    func testWorkspaceViewModelUsesProfileNameAndEmailForMemberPresentation() {
        let workspaceId = UUID()
        let userId = UUID()
        let member = WorkspaceMember(
            id: UUID(),
            workspaceId: workspaceId,
            userId: userId,
            role: .member,
            status: .active,
            invitedAt: nil,
            acceptedAt: nil
        )
        let viewModel = WorkspaceViewModel()
        viewModel.memberProfiles = [
            userId: AppUser(
                id: userId,
                email: "user@example.com",
                name: "Test User",
                avatarUrl: nil,
                preferredCurrency: "TRY",
                createdAt: nil,
                updatedAt: nil
            )
        ]

        XCTAssertEqual(viewModel.displayName(for: member), "Test User")
        XCTAssertEqual(viewModel.subtitle(for: member), "user@example.com")
    }

    func testWorkspaceViewModelResolvesStaleActiveWorkspaceToFirstAvailable() {
        let current = Workspace(
            id: UUID(),
            name: "Eski Workspace",
            ownerId: UUID(),
            createdAt: nil
        )
        let expected = Workspace(
            id: UUID(),
            name: "Yeni Workspace",
            ownerId: UUID(),
            createdAt: nil
        )
        let viewModel = WorkspaceViewModel()

        let resolved = viewModel.resolvedActiveWorkspace(current: current, available: [expected])

        XCTAssertEqual(resolved?.id, expected.id)
    }

    func testWorkspaceViewModelSortsMembersByStatusRoleAndName() {
        let workspaceId = UUID()
        let ownerId = UUID()
        let memberId = UUID()
        let pendingId = UUID()
        let owner = WorkspaceMember(
            id: UUID(),
            workspaceId: workspaceId,
            userId: ownerId,
            role: .owner,
            status: .active,
            invitedAt: nil,
            acceptedAt: nil
        )
        let member = WorkspaceMember(
            id: UUID(),
            workspaceId: workspaceId,
            userId: memberId,
            role: .member,
            status: .active,
            invitedAt: nil,
            acceptedAt: nil
        )
        let pending = WorkspaceMember(
            id: UUID(),
            workspaceId: workspaceId,
            userId: pendingId,
            role: .member,
            status: .pending,
            invitedAt: nil,
            acceptedAt: nil
        )
        let viewModel = WorkspaceViewModel()
        viewModel.memberProfiles = [
            ownerId: AppUser(
                id: ownerId,
                email: "owner@example.com",
                name: "Zeynep",
                avatarUrl: nil,
                preferredCurrency: "TRY",
                createdAt: nil,
                updatedAt: nil
            ),
            memberId: AppUser(
                id: memberId,
                email: "member@example.com",
                name: "Ahmet",
                avatarUrl: nil,
                preferredCurrency: "TRY",
                createdAt: nil,
                updatedAt: nil
            ),
            pendingId: AppUser(
                id: pendingId,
                email: "pending@example.com",
                name: "Can",
                avatarUrl: nil,
                preferredCurrency: "TRY",
                createdAt: nil,
                updatedAt: nil
            )
        ]

        let sorted = viewModel.sortedMembers([pending, owner, member])

        XCTAssertEqual(sorted.map(\.userId), [ownerId, memberId, pendingId])
    }

    func testWorkspaceViewModelFallsBackToEmailAndDefaultWorkspaceName() {
        let workspaceId = UUID()
        let userId = UUID()
        let member = WorkspaceMember(
            id: UUID(),
            workspaceId: workspaceId,
            userId: userId,
            role: .member,
            status: .active,
            invitedAt: nil,
            acceptedAt: nil
        )
        let invitation = WorkspaceMember(
            id: UUID(),
            workspaceId: workspaceId,
            userId: userId,
            role: .member,
            status: .pending,
            invitedAt: nil,
            acceptedAt: nil
        )
        let viewModel = WorkspaceViewModel()
        viewModel.memberProfiles = [
            userId: AppUser(
                id: userId,
                email: "fallback@example.com",
                name: "",
                avatarUrl: nil,
                preferredCurrency: "TRY",
                createdAt: nil,
                updatedAt: nil
            )
        ]

        XCTAssertEqual(viewModel.displayName(for: member), "fallback@example.com")
        XCTAssertEqual(viewModel.workspaceName(for: invitation), "Workspace")
    }

    func testWorkspaceViewModelUsesInvitationWorkspaceName() {
        let workspaceId = UUID()
        let invitation = WorkspaceMember(
            id: UUID(),
            workspaceId: workspaceId,
            userId: UUID(),
            role: .member,
            status: .pending,
            invitedAt: nil,
            acceptedAt: nil
        )
        let viewModel = WorkspaceViewModel()
        viewModel.invitationWorkspaces = [
            workspaceId: Workspace(
                id: workspaceId,
                name: "Ortak Butce",
                ownerId: UUID(),
                createdAt: nil
            )
        ]

        XCTAssertEqual(viewModel.workspaceName(for: invitation), "Ortak Butce")
    }

    func testTransactionFeedQueryTrimsWhitespaceOnlySearchText() {
        let query = TransactionFeedQuery(
            workspaceId: UUID(),
            searchText: "   "
        )

        XCTAssertEqual(query.searchText, "")
    }

    func testTransactionViewModelMergesPagedTransactionsWithoutDuplicates() {
        let workspaceId = UUID()
        let existing = Transaction(
            id: UUID(),
            workspaceId: workspaceId,
            userId: UUID(),
            type: .expense,
            categoryId: nil,
            amount: 100,
            currency: "TRY",
            date: Date(),
            description: "Ilk",
            paymentMethod: nil,
            visibilityScope: .personal,
            isRecurring: false,
            recurrenceInterval: nil,
            tags: nil,
            createdAt: nil,
            updatedAt: nil
        )
        let newTransaction = Transaction(
            id: UUID(),
            workspaceId: workspaceId,
            userId: UUID(),
            type: .income,
            categoryId: nil,
            amount: 250,
            currency: "TRY",
            date: Date().addingTimeInterval(-60),
            description: "Ikinci",
            paymentMethod: nil,
            visibilityScope: .shared,
            isRecurring: false,
            recurrenceInterval: nil,
            tags: nil,
            createdAt: nil,
            updatedAt: nil
        )
        let viewModel = TransactionViewModel()

        let merged = viewModel.mergeUniqueTransactions(
            existing: [existing],
            incoming: [existing, newTransaction]
        )

        XCTAssertEqual(merged.map(\.id), [existing.id, newTransaction.id])
    }

    func testTransactionViewModelMatchesFeedQueryAndRejectsDifferentFilters() {
        let workspaceId = UUID()
        let categoryId = UUID()
        let matchingTransaction = Transaction(
            id: UUID(),
            workspaceId: workspaceId,
            userId: UUID(),
            type: .expense,
            categoryId: categoryId,
            amount: 320,
            currency: "TRY",
            date: Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 20))!,
            description: "Haftalik market alisverisi",
            paymentMethod: nil,
            visibilityScope: .shared,
            isRecurring: false,
            recurrenceInterval: nil,
            tags: nil,
            createdAt: nil,
            updatedAt: nil
        )
        let nonMatchingTransaction = Transaction(
            id: UUID(),
            workspaceId: workspaceId,
            userId: UUID(),
            type: .income,
            categoryId: nil,
            amount: 500,
            currency: "TRY",
            date: Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 20))!,
            description: "Maas",
            paymentMethod: nil,
            visibilityScope: .personal,
            isRecurring: false,
            recurrenceInterval: nil,
            tags: nil,
            createdAt: nil,
            updatedAt: nil
        )
        let query = TransactionFeedQuery(
            workspaceId: workspaceId,
            type: .expense,
            categoryId: categoryId,
            visibilityScope: .shared,
            searchText: "market",
            startDate: Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 1))!,
            endDate: Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 31))!
        )
        let viewModel = TransactionViewModel()

        XCTAssertTrue(viewModel.matches(transaction: matchingTransaction, query: query))
        XCTAssertFalse(viewModel.matches(transaction: nonMatchingTransaction, query: query))
    }

    func testTransactionFilterSupportDoesNotShowFilteredEmptyStateWithoutAnyTransactions() {
        XCTAssertFalse(
            TransactionFilterSupport.isFilterResultEmpty(
                hasTransactions: false,
                hasActiveFilters: true,
                searchText: "market"
            )
        )
    }

    func testTransactionViewModelReconcilesVisibleTransactionsWithActiveFeedQuery() {
        let workspaceId = UUID()
        let categoryId = UUID()
        let matching = Transaction(
            id: UUID(),
            workspaceId: workspaceId,
            userId: UUID(),
            type: .expense,
            categoryId: categoryId,
            amount: 300,
            currency: "TRY",
            date: Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 20))!,
            description: "Market",
            paymentMethod: nil,
            visibilityScope: .shared,
            isRecurring: false,
            recurrenceInterval: nil,
            tags: nil,
            createdAt: nil,
            updatedAt: nil
        )
        var edited = matching
        edited.type = .income

        let viewModel = TransactionViewModel()
        let query = TransactionFeedQuery(
            workspaceId: workspaceId,
            type: .expense,
            categoryId: categoryId,
            visibilityScope: .shared,
            searchText: "market"
        )

        let inserted = viewModel.reconciledVisibleTransactions(
            current: [],
            with: matching,
            query: query
        )
        XCTAssertEqual(inserted.map(\.id), [matching.id])

        let removed = viewModel.reconciledVisibleTransactions(
            current: inserted,
            with: edited,
            query: query
        )
        XCTAssertTrue(removed.isEmpty)
    }

    func testWorkspaceCollaborationErrorsExposeUserFriendlyMessages() {
        XCTAssertEqual(
            WorkspaceCollaborationError.invalidEmail.errorDescription,
            "Gecerli bir e-posta girin."
        )
        XCTAssertEqual(
            WorkspaceCollaborationError.userNotFound.errorDescription,
            "Bu e-posta ile eslesen kullanici bulunamadi."
        )
        XCTAssertEqual(
            WorkspaceCollaborationError.cannotInviteYourself.errorDescription,
            "Kendinizi davet edemezsiniz."
        )
        XCTAssertEqual(
            WorkspaceCollaborationError.alreadyMemberOrInvited.errorDescription,
            "Bu kullanici zaten uye veya bekleyen davet durumunda."
        )
    }
}

private actor CallRecorder {
    private(set) var calls: [String] = []

    func record(_ value: String) {
        calls.append(value)
    }
}
