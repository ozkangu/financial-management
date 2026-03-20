import XCTest
import SwiftData
@testable import FinansFlow

@MainActor
final class FinansFlowTests: XCTestCase {
    private func makeContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: Asset.self,
            Liability.self,
            NetWorthSnapshot.self,
            PassiveIncome.self,
            Category.self,
            Transaction.self,
            configurations: configuration
        )
    }

    func testDashboardNetWorthSummaryCalculatesTotalsAndDeltaFromLatestSnapshot() {
        let assets = [
            Asset(name: "Nakit", type: .cash, value: 150_000),
            Asset(name: "Banka", type: .bankAccount, value: 50_000)
        ]
        let liabilities = [
            Liability(
                name: "Kredi Kartı",
                type: .creditCard,
                totalAmount: 20_000,
                remainingAmount: 12_000
            )
        ]
        let snapshots = [
            NetWorthSnapshot(
                date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
                totalAssets: 180_000,
                totalLiabilities: 10_000,
                netWorth: 170_000
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

    func testDashboardPassiveIncomeSummaryCalculatesMonthlyAmountRatioAndNextPayment() {
        let passiveIncomes = [
            PassiveIncome(
                type: .dividend,
                amount: 1_200,
                frequency: .monthly,
                nextPaymentDate: Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 25)),
                descriptionText: "Fon Temettusu"
            ),
            PassiveIncome(
                type: .rent,
                amount: 12_000,
                frequency: .yearly,
                nextPaymentDate: Calendar.current.date(from: DateComponents(year: 2026, month: 4, day: 5)),
                descriptionText: "Depo Kirasi"
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

    func testDashboardCategoryBudgetSummariesHighlightExceededAndWarningBudgets() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let food = Category(
            name: "Market",
            type: .expense,
            color: "#FF0000",
            icon: "cart",
            monthlyBudget: 1_000
        )
        let transport = Category(
            name: "Ulasim",
            type: .expense,
            color: "#00FF00",
            icon: "car",
            monthlyBudget: 500
        )
        let transactions = [
            Transaction(
                type: .expense,
                category: food,
                amount: 1_200,
                date: Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 12))!
            ),
            Transaction(
                type: .expense,
                category: transport,
                amount: 420,
                date: Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 10))!
            )
        ]

        [food, transport].forEach(context.insert)
        transactions.forEach(context.insert)
        try context.save()

        let summaries = DashboardMetrics.categoryBudgetSummaries(
            categories: [food, transport],
            transactions: transactions,
            referenceDate: Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 20))!
        )

        XCTAssertEqual(summaries.map(\.name), ["Market", "Ulasim"])
        XCTAssertEqual(summaries[0].status, .exceeded)
        XCTAssertEqual(summaries[1].status, .warning)
    }

    func testDashboardCategoryBudgetSummariesIncludeSubcategorySpendWithoutDoubleCountingBudgetedChildren() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let parent = Category(
            name: "Ev",
            type: .expense,
            color: "#111111",
            icon: "house",
            monthlyBudget: 2_000
        )
        let budgetedChild = Category(
            name: "Fatura",
            type: .expense,
            parent: parent,
            color: "#222222",
            icon: "bolt",
            monthlyBudget: 800
        )
        let unbudgetedChild = Category(
            name: "Elektrik",
            type: .expense,
            parent: parent,
            color: "#333333",
            icon: "bolt.fill"
        )
        let transactions = [
            Transaction(
                type: .expense,
                category: budgetedChild,
                amount: 600,
                date: Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 8))!
            ),
            Transaction(
                type: .expense,
                category: unbudgetedChild,
                amount: 250,
                date: Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 9))!
            )
        ]

        [parent, budgetedChild, unbudgetedChild].forEach(context.insert)
        transactions.forEach(context.insert)
        try context.save()

        let summaries = DashboardMetrics.categoryBudgetSummaries(
            categories: [parent, budgetedChild, unbudgetedChild],
            transactions: transactions,
            referenceDate: Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 20))!
        )

        XCTAssertEqual(summaries.first(where: { $0.id == parent.id })?.spent, 250)
        XCTAssertEqual(summaries.first(where: { $0.id == budgetedChild.id })?.spent, 600)
    }

    func testDashboardInsightsGenerateExpectedMessages() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let market = Category(
            name: "Market",
            type: .expense,
            color: "#FF0000",
            icon: "cart"
        )
        let rent = Category(
            name: "Kira",
            type: .expense,
            color: "#00FF00",
            icon: "house"
        )
        let referenceDate = Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 20))!
        let transactions = [
            Transaction(type: .income, amount: 10_000, date: referenceDate),
            Transaction(type: .expense, category: market, amount: 2_000, date: referenceDate),
            Transaction(type: .expense, category: rent, amount: 3_500, date: referenceDate),
            Transaction(
                type: .income,
                amount: 8_000,
                date: Calendar.current.date(from: DateComponents(year: 2026, month: 2, day: 15))!
            )
        ]
        let liabilities = [
            Liability(
                name: "Kredi",
                type: .personalLoan,
                totalAmount: 50_000,
                remainingAmount: 40_000,
                monthlyPayment: 4_500
            )
        ]

        [market, rent].forEach(context.insert)
        transactions.forEach(context.insert)
        liabilities.forEach(context.insert)
        try context.save()

        let insights = DashboardMetrics.insights(
            transactions: transactions,
            categories: [market, rent],
            liabilities: liabilities,
            referenceDate: referenceDate
        )

        XCTAssertEqual(insights.count, 3)
        XCTAssertTrue(insights.contains(where: { $0.message.contains("Kira") }))
        XCTAssertTrue(insights.contains(where: { $0.title == "Aylik Degisim" }))
        XCTAssertTrue(insights.contains(where: { $0.title == "Borc Baskisi" }))
    }

    func testCSVExportBuilderIncludesTransactionFields() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let category = Category(
            name: "Market",
            type: .expense,
            color: "#FF0000",
            icon: "cart"
        )
        let transaction = Transaction(
            type: .expense,
            category: category,
            amount: 450.75,
            date: Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 20))!,
            descriptionText: "Haftalik market"
        )

        context.insert(category)
        context.insert(transaction)
        try context.save()

        let csv = CSVExportBuilder.transactionsCSV(
            transactions: [transaction],
            categories: [category]
        )

        XCTAssertTrue(csv.contains("\"Tarih\",\"Tur\",\"Tutar\",\"Para Birimi\",\"Kategori\",\"Aciklama\""))
        XCTAssertTrue(csv.contains("\"Market\""))
        XCTAssertTrue(csv.contains("\"Haftalik market\""))
    }

    func testCSVExportBuilderEscapesQuotesCommasAndNewlines() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let category = Category(
            name: "Market, Manav",
            type: .expense,
            color: "#00AA00",
            icon: "cart"
        )
        let transaction = Transaction(
            type: .expense,
            category: category,
            amount: 99.9,
            date: Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 21))!,
            descriptionText: "Sebze \"indirim\"\n2 kalem"
        )

        context.insert(category)
        context.insert(transaction)
        try context.save()

        let csv = CSVExportBuilder.transactionsCSV(
            transactions: [transaction],
            categories: [category]
        )

        XCTAssertTrue(csv.contains("\"Market, Manav\""))
        XCTAssertTrue(csv.contains("\"Sebze \"\"indirim\"\"\n2 kalem\""))
    }
}
