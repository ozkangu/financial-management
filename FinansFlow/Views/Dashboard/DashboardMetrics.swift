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

struct DashboardInsightItem: Equatable, Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

enum DashboardBudgetStatus: Equatable {
    case onTrack
    case warning
    case exceeded
}

struct DashboardCategoryBudgetSummary: Equatable, Identifiable {
    let id: UUID
    let name: String
    let budget: Double
    let spent: Double

    var remaining: Double {
        budget - spent
    }

    var utilization: Double {
        guard budget > 0 else { return 0 }
        return spent / budget
    }

    var status: DashboardBudgetStatus {
        if spent > budget {
            return .exceeded
        }
        if utilization >= 0.8 {
            return .warning
        }
        return .onTrack
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
            nextPaymentDescription: nextIncome?.descriptionText ?? nextIncome?.type.displayName
        )
    }

    static func insights(
        transactions: [Transaction],
        categories: [Category],
        liabilities: [Liability],
        referenceDate: Date
    ) -> [DashboardInsightItem] {
        [
            topExpenseCategoryInsight(
                transactions: transactions,
                categories: categories,
                referenceDate: referenceDate
            ),
            monthlyChangeInsight(
                transactions: transactions,
                referenceDate: referenceDate
            ),
            debtPressureInsight(
                transactions: transactions,
                liabilities: liabilities,
                referenceDate: referenceDate
            )
        ]
        .compactMap { $0 }
    }

    static func categoryBudgetSummaries(
        categories: [Category],
        transactions: [Transaction],
        referenceDate: Date
    ) -> [DashboardCategoryBudgetSummary] {
        let expenseTransactions = transactions.filter {
            $0.type == .expense &&
            $0.date >= referenceDate.startOfMonth &&
            $0.date <= referenceDate.endOfMonth
        }

        return categories
            .filter { category in
                category.type == .expense &&
                (category.monthlyBudget ?? 0) > 0
            }
            .map { category in
                let includedCategoryIds = descendantCategoryIds(
                    for: category.id,
                    in: categories
                )
                let spent = expenseTransactions
                    .filter { transaction in
                        guard let categoryId = transaction.category?.id else { return false }
                        return includedCategoryIds.contains(categoryId)
                    }
                    .reduce(0) { $0 + $1.amount }

                return DashboardCategoryBudgetSummary(
                    id: category.id,
                    name: category.name,
                    budget: category.monthlyBudget ?? 0,
                    spent: spent
                )
            }
            .sorted { lhs, rhs in
                if lhs.status != rhs.status {
                    return budgetStatusRank(lhs.status) < budgetStatusRank(rhs.status)
                }
                return lhs.utilization > rhs.utilization
            }
    }

    static func topBudgetAlert(
        categories: [Category],
        transactions: [Transaction],
        referenceDate: Date
    ) -> DashboardCategoryBudgetSummary? {
        categoryBudgetSummaries(
            categories: categories,
            transactions: transactions,
            referenceDate: referenceDate
        )
        .first(where: { $0.status != .onTrack })
    }

    private static func topExpenseCategoryInsight(
        transactions: [Transaction],
        categories: [Category],
        referenceDate: Date
    ) -> DashboardInsightItem? {
        let currentMonthExpenses = transactions.filter {
            $0.type == .expense &&
            $0.date >= referenceDate.startOfMonth &&
            $0.date <= referenceDate.endOfMonth
        }

        let grouped = Dictionary(grouping: currentMonthExpenses) { $0.category?.id }
        guard
            let topCategoryGroup = grouped.max(by: {
                $0.value.reduce(0) { $0 + $1.amount } < $1.value.reduce(0) { $0 + $1.amount }
            })
        else {
            return DashboardInsightItem(
                title: "Harcama Dagilimi",
                message: "Bu ay kategori bazli gider verisi henuz olusmadi."
            )
        }

        let totalAmount = topCategoryGroup.value.reduce(0) { $0 + $1.amount }
        let categoryName = topCategoryGroup.key.flatMap { categoryId in
            categories.first(where: { $0.id == categoryId })?.name
        } ?? "Diger"

        return DashboardInsightItem(
            title: "En Yuksek Gider",
            message: "Bu ay en cok harcama \(categoryName) kategorisinde: \(totalAmount.formatted())."
        )
    }

    private static func monthlyChangeInsight(
        transactions: [Transaction],
        referenceDate: Date
    ) -> DashboardInsightItem {
        let currentMonth = monthSummary(for: referenceDate, transactions: transactions)
        let previousMonth = monthSummary(for: referenceDate.monthsAgo(1), transactions: transactions)

        let incomeDelta = currentMonth.income - previousMonth.income
        let expenseDelta = currentMonth.expense - previousMonth.expense

        if previousMonth.income == 0 && previousMonth.expense == 0 {
            return DashboardInsightItem(
                title: "Aylik Karsilastirma",
                message: "Gecen ay veri olmadigi icin degisim orani henuz hesaplanamiyor."
            )
        }

        let incomeText = changeText(
            label: "gelir",
            amount: incomeDelta
        )
        let expenseText = changeText(
            label: "gider",
            amount: expenseDelta
        )

        return DashboardInsightItem(
            title: "Aylik Degisim",
            message: "Gecen aya gore \(incomeText), \(expenseText)."
        )
    }

    private static func debtPressureInsight(
        transactions: [Transaction],
        liabilities: [Liability],
        referenceDate: Date
    ) -> DashboardInsightItem {
        let currentIncome = transactions
            .filter { $0.type == .income && $0.date >= referenceDate.startOfMonth && $0.date <= referenceDate.endOfMonth }
            .reduce(0) { $0 + $1.amount }
        let currentExpense = transactions
            .filter { $0.type == .expense && $0.date >= referenceDate.startOfMonth && $0.date <= referenceDate.endOfMonth }
            .reduce(0) { $0 + $1.amount }
        let totalMonthlyDebt = liabilities.reduce(0) { $0 + ($1.monthlyPayment ?? 0) }
        let netCashFlow = currentIncome - currentExpense

        if totalMonthlyDebt > 0 && currentIncome > 0 && (totalMonthlyDebt / currentIncome) >= 0.4 {
            return DashboardInsightItem(
                title: "Borc Baskisi",
                message: "Aylik borc odemeleri gelirin \(Int((totalMonthlyDebt / currentIncome) * 100))% seviyesinde. Nakit akisini yakindan izleyin."
            )
        }

        if netCashFlow > 0 {
            return DashboardInsightItem(
                title: "Nakit Akisi",
                message: "Bu ay pozitif nakit akisi var. Net fark \(netCashFlow.formatted())."
            )
        }

        if netCashFlow < 0 {
            return DashboardInsightItem(
                title: "Nakit Akisi",
                message: "Bu ay giderler geliri asti. Net acik \(abs(netCashFlow).formatted())."
            )
        }

        return DashboardInsightItem(
            title: "Nakit Dengesi",
            message: "Bu ay gelir ve gider dengesi basa bas seviyede."
        )
    }

    private static func monthSummary(
        for month: Date,
        transactions: [Transaction]
    ) -> (income: Double, expense: Double) {
        let income = transactions
            .filter { $0.type == .income && $0.date >= month.startOfMonth && $0.date <= month.endOfMonth }
            .reduce(0) { $0 + $1.amount }
        let expense = transactions
            .filter { $0.type == .expense && $0.date >= month.startOfMonth && $0.date <= month.endOfMonth }
            .reduce(0) { $0 + $1.amount }

        return (income, expense)
    }

    private static func changeText(label: String, amount: Double) -> String {
        if amount == 0 {
            return "\(label) ayni seviyede"
        }

        let direction = amount > 0 ? "artti" : "azaldi"
        return "\(label) \(abs(amount).formatted()) kadar \(direction)"
    }

    private static func budgetStatusRank(_ status: DashboardBudgetStatus) -> Int {
        switch status {
        case .exceeded:
            return 0
        case .warning:
            return 1
        case .onTrack:
            return 2
        }
    }

    private static func descendantCategoryIds(
        for rootId: UUID,
        in categories: [Category]
    ) -> Set<UUID> {
        let childrenByParent = Dictionary(grouping: categories) { $0.parent?.id }

        func collectChildren(from categoryId: UUID) -> Set<UUID> {
            var collected: Set<UUID> = []

            for child in childrenByParent[categoryId] ?? [] {
                let childHasBudget = (child.monthlyBudget ?? 0) > 0
                if childHasBudget {
                    continue
                }

                collected.insert(child.id)
                collected.formUnion(collectChildren(from: child.id))
            }

            return collected
        }

        func collect(from categoryId: UUID) -> Set<UUID> {
            var collected: Set<UUID> = [categoryId]
            collected.formUnion(collectChildren(from: categoryId))
            return collected
        }

        return collect(from: rootId)
    }
}
