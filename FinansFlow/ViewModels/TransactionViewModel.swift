import Foundation

struct TransactionFeedQuery: Equatable, Sendable {
    let workspaceId: UUID
    let type: TransactionType?
    let categoryId: UUID?
    let visibilityScope: VisibilityScope?
    let searchText: String
    let startDate: Date?
    let endDate: Date?

    init(
        workspaceId: UUID,
        type: TransactionType? = nil,
        categoryId: UUID? = nil,
        visibilityScope: VisibilityScope? = nil,
        searchText: String = "",
        startDate: Date? = nil,
        endDate: Date? = nil
    ) {
        self.workspaceId = workspaceId
        self.type = type
        self.categoryId = categoryId
        self.visibilityScope = visibilityScope
        self.searchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        self.startDate = startDate
        self.endDate = endDate
    }

    var cacheKey: String {
        [
            workspaceId.uuidString,
            type?.rawValue ?? "all",
            categoryId?.uuidString ?? "all",
            visibilityScope?.rawValue ?? "all",
            searchText,
            startDate?.ISO8601Format() ?? "none",
            endDate?.ISO8601Format() ?? "none"
        ].joined(separator: "|")
    }
}

@Observable
final class TransactionViewModel {
    var transactions: [Transaction] = []
    var visibleTransactions: [Transaction] = []
    var isLoading = false
    var isFeedLoading = false
    var errorMessage: String?
    var feedErrorMessage: String?
    var hasMorePages = true
    var hasMoreFeedPages = true

    private let service = SupabaseService.shared
    private var currentPage = 0
    private var currentFeedPage = 0
    private let pageSize = AppConstants.pageSize
    private var latestWorkspaceId: UUID?
    private var latestFeedQuery: TransactionFeedQuery?

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
        latestWorkspaceId = workspaceId
        if reset {
            currentPage = 0
            transactions = []
            hasMorePages = true
        }

        guard hasMorePages else { return }
        isLoading = true
        defer {
            if latestWorkspaceId == workspaceId {
                isLoading = false
            }
        }

        do {
            let fetched: [Transaction] = try await service.fetchAll(
                from: "transactions",
                filters: [("workspace_id", workspaceId.uuidString)],
                orderBy: "date",
                ascending: false,
                limit: pageSize
            )
            guard latestWorkspaceId == workspaceId else { return }
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
            guard latestWorkspaceId == workspaceId else { return }
            errorMessage = error.localizedDescription
        }
    }

    func loadTransactionFeed(query: TransactionFeedQuery, reset: Bool = false) async {
        latestFeedQuery = query
        if reset {
            currentFeedPage = 0
            visibleTransactions = []
            hasMoreFeedPages = true
        }

        guard hasMoreFeedPages else { return }
        isFeedLoading = true
        defer {
            if latestFeedQuery == query {
                isFeedLoading = false
            }
        }

        do {
            let fetched = try await service.fetchTransactionsPage(
                query: query,
                offset: currentFeedPage * pageSize,
                limit: pageSize
            )
            guard latestFeedQuery == query else { return }
            if fetched.count < pageSize {
                hasMoreFeedPages = false
            }
            if reset {
                visibleTransactions = fetched
            } else {
                visibleTransactions = mergeUniqueTransactions(
                    existing: visibleTransactions,
                    incoming: fetched
                )
            }
            currentFeedPage += 1
        } catch {
            guard latestFeedQuery == query else { return }
            feedErrorMessage = error.localizedDescription
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
        visibleTransactions = reconciledVisibleTransactions(
            current: visibleTransactions,
            with: created,
            query: latestFeedQuery
        )
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
        visibleTransactions = reconciledVisibleTransactions(
            current: visibleTransactions,
            with: transaction,
            query: latestFeedQuery
        )
    }

    func deleteTransaction(_ transaction: Transaction) async throws {
        try await service.delete(from: "transactions", id: transaction.id)
        transactions.removeAll { $0.id == transaction.id }
        visibleTransactions.removeAll { $0.id == transaction.id }
    }

    // MARK: - Filtering

    func filteredTransactions(
        type: TransactionType? = nil,
        categoryId: UUID? = nil,
        visibilityScope: VisibilityScope? = nil,
        searchText: String = "",
        startDate: Date? = nil,
        endDate: Date? = nil
    ) -> [Transaction] {
        transactions.filter { tx in
            if let type, tx.type != type { return false }
            if let categoryId, tx.categoryId != categoryId { return false }
            if let visibilityScope, tx.visibilityScope != visibilityScope { return false }
            if !searchText.isEmpty,
               !(tx.description?.localizedCaseInsensitiveContains(searchText) ?? false) {
                return false
            }
            if let startDate, tx.date < startDate { return false }
            if let endDate, tx.date > endDate { return false }
            return true
        }
    }

    func mergeUniqueTransactions(
        existing: [Transaction],
        incoming: [Transaction]
    ) -> [Transaction] {
        var seenIds = Set(existing.map(\.id))
        var merged = existing

        for transaction in incoming where seenIds.insert(transaction.id).inserted {
            merged.append(transaction)
        }

        return merged
    }

    func shouldIncludeInVisibleTransactions(_ transaction: Transaction) -> Bool {
        guard let latestFeedQuery else { return true }
        return matches(transaction: transaction, query: latestFeedQuery)
    }

    func reconciledVisibleTransactions(
        current: [Transaction],
        with transaction: Transaction,
        query: TransactionFeedQuery?
    ) -> [Transaction] {
        var updated = current
        let shouldInclude = if let query {
            matches(transaction: transaction, query: query)
        } else {
            true
        }

        if let idx = updated.firstIndex(where: { $0.id == transaction.id }) {
            if shouldInclude {
                updated[idx] = transaction
            } else {
                updated.remove(at: idx)
            }
            return updated
        }

        if shouldInclude {
            updated.insert(transaction, at: 0)
        }

        return updated
    }

    func matches(transaction: Transaction, query: TransactionFeedQuery) -> Bool {
        if transaction.workspaceId != query.workspaceId { return false }
        if let type = query.type, transaction.type != type { return false }
        if let categoryId = query.categoryId, transaction.categoryId != categoryId { return false }
        if let visibilityScope = query.visibilityScope, transaction.visibilityScope != visibilityScope { return false }
        if !query.searchText.isEmpty,
           !(transaction.description?.localizedCaseInsensitiveContains(query.searchText) ?? false) {
            return false
        }
        if let startDate = query.startDate, transaction.date < startDate { return false }
        if let endDate = query.endDate, transaction.date > endDate { return false }
        return true
    }
}
