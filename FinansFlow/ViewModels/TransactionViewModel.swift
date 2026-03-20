import Foundation

@Observable
final class TransactionViewModel {
    var transactions: [Transaction] = []
    var isLoading = false
    var errorMessage: String?
    var hasMorePages = true

    private let service = SupabaseService.shared
    private var currentPage = 0
    private let pageSize = AppConstants.pageSize

    // MARK: - Computed

    var incomeTransactions: [Transaction] {
        transactions.filter { $0.type == .income }
    }

    var expenseTransactions: [Transaction] {
        transactions.filter { $0.type == .expense }
    }

    func totalIncome(for month: Date) -> Double {
        let start = month.startOfMonth
        let end = month.endOfMonth
        return transactions
            .filter { $0.type == .income && $0.date >= start && $0.date <= end }
            .reduce(0) { $0 + $1.amount }
    }

    func totalExpense(for month: Date) -> Double {
        let start = month.startOfMonth
        let end = month.endOfMonth
        return transactions
            .filter { $0.type == .expense && $0.date >= start && $0.date <= end }
            .reduce(0) { $0 + $1.amount }
    }

    func netCashFlow(for month: Date) -> Double {
        totalIncome(for: month) - totalExpense(for: month)
    }

    // MARK: - Grouped by date

    var groupedByDate: [(date: String, transactions: [Transaction])] {
        let grouped = Dictionary(grouping: transactions) { transaction in
            transaction.date.displayString
        }
        return grouped.map { (date: $0.key, transactions: $0.value) }
            .sorted { $0.transactions.first?.date ?? Date() > $1.transactions.first?.date ?? Date() }
    }

    // MARK: - CRUD

    func loadTransactions(workspaceId: UUID, reset: Bool = false) async {
        if reset {
            currentPage = 0
            transactions = []
            hasMorePages = true
        }

        guard hasMorePages else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let offset = currentPage * pageSize
            let fetched: [Transaction] = try await service.fetchAll(
                from: "transactions",
                filters: [("workspace_id", workspaceId.uuidString)],
                orderBy: "date",
                ascending: false,
                limit: pageSize
            )
            if fetched.count < pageSize {
                hasMorePages = false
            }
            if reset {
                transactions = fetched
            } else {
                transactions.append(contentsOf: fetched)
            }
            currentPage += 1
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createTransaction(
        workspaceId: UUID,
        userId: UUID,
        type: TransactionType,
        categoryId: UUID?,
        amount: Double,
        date: Date,
        description: String?,
        paymentMethod: String?,
        visibilityScope: VisibilityScope,
        isRecurring: Bool,
        recurrenceInterval: RecurrenceInterval?,
        tags: [String]?
    ) async throws {
        struct NewTransaction: Encodable {
            let workspace_id: String
            let user_id: String
            let type: String
            let category_id: String?
            let amount: Double
            let currency: String
            let date: String
            let description: String?
            let payment_method: String?
            let visibility_scope: String
            let is_recurring: Bool
            let recurrence_interval: String?
            let tags: [String]?
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let new = NewTransaction(
            workspace_id: workspaceId.uuidString,
            user_id: userId.uuidString,
            type: type.rawValue,
            category_id: categoryId?.uuidString,
            amount: amount,
            currency: AppConstants.defaultCurrency,
            date: dateFormatter.string(from: date),
            description: description,
            payment_method: paymentMethod,
            visibility_scope: visibilityScope.rawValue,
            is_recurring: isRecurring,
            recurrence_interval: recurrenceInterval?.rawValue,
            tags: tags
        )

        let created: Transaction = try await service.insertReturning(into: "transactions", value: new)
        transactions.insert(created, at: 0)
    }

    func updateTransaction(_ transaction: Transaction) async throws {
        struct UpdatePayload: Encodable {
            let category_id: String?
            let amount: Double
            let date: String
            let description: String?
            let payment_method: String?
            let visibility_scope: String
            let is_recurring: Bool
            let recurrence_interval: String?
            let tags: [String]?
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        try await service.update(
            table: "transactions",
            id: transaction.id,
            value: UpdatePayload(
                category_id: transaction.categoryId?.uuidString,
                amount: transaction.amount,
                date: dateFormatter.string(from: transaction.date),
                description: transaction.description,
                payment_method: transaction.paymentMethod,
                visibility_scope: transaction.visibilityScope.rawValue,
                is_recurring: transaction.isRecurring,
                recurrence_interval: transaction.recurrenceInterval?.rawValue,
                tags: transaction.tags
            )
        )

        if let idx = transactions.firstIndex(where: { $0.id == transaction.id }) {
            transactions[idx] = transaction
        }
    }

    func deleteTransaction(_ transaction: Transaction) async throws {
        try await service.delete(from: "transactions", id: transaction.id)
        transactions.removeAll { $0.id == transaction.id }
    }

    // MARK: - Filtering

    func filteredTransactions(
        type: TransactionType? = nil,
        categoryId: UUID? = nil,
        searchText: String = "",
        startDate: Date? = nil,
        endDate: Date? = nil
    ) -> [Transaction] {
        transactions.filter { tx in
            if let type, tx.type != type { return false }
            if let categoryId, tx.categoryId != categoryId { return false }
            if !searchText.isEmpty,
               !(tx.description?.localizedCaseInsensitiveContains(searchText) ?? false) {
                return false
            }
            if let startDate, tx.date < startDate { return false }
            if let endDate, tx.date > endDate { return false }
            return true
        }
    }
}
