import Foundation
import SwiftData

@Observable
final class TransactionViewModel {
    var transactions: [Transaction] = []
    var isLoading = false
    var errorMessage: String?

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

    func loadTransactions(context: ModelContext) {
        isLoading = true
        defer { isLoading = false }

        do {
            let descriptor = FetchDescriptor<Transaction>(sortBy: [SortDescriptor(\.date, order: .reverse)])
            transactions = try context.fetch(descriptor)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createTransaction(
        context: ModelContext,
        type: TransactionType,
        category: Category?,
        amount: Double,
        date: Date,
        descriptionText: String?,
        paymentMethod: String?,
        isRecurring: Bool,
        recurrenceInterval: RecurrenceInterval?,
        tags: [String]?
    ) {
        let transaction = Transaction(
            type: type,
            category: category,
            amount: amount,
            date: date,
            descriptionText: descriptionText,
            paymentMethod: paymentMethod,
            isRecurring: isRecurring,
            recurrenceInterval: recurrenceInterval,
            tags: tags
        )
        context.insert(transaction)
        try? context.save()
        transactions.insert(transaction, at: 0)
    }

    func updateTransaction(_ transaction: Transaction, context: ModelContext) {
        transaction.updatedAt = Date()
        try? context.save()
    }

    func deleteTransaction(_ transaction: Transaction, context: ModelContext) {
        context.delete(transaction)
        try? context.save()
        transactions.removeAll { $0.id == transaction.id }
    }

    // MARK: - Filtering

    func filteredTransactions(
        type: TransactionType? = nil,
        category: Category? = nil,
        searchText: String = "",
        startDate: Date? = nil,
        endDate: Date? = nil
    ) -> [Transaction] {
        transactions.filter { tx in
            if let type, tx.type != type { return false }
            if let category, tx.category?.id != category.id { return false }
            if !searchText.isEmpty,
               !(tx.descriptionText?.localizedCaseInsensitiveContains(searchText) ?? false) {
                return false
            }
            if let startDate, tx.date < startDate { return false }
            if let endDate, tx.date > endDate { return false }
            return true
        }
    }
}
