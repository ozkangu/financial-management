import Foundation
import SwiftData

enum TransactionType: String, Codable, Sendable, CaseIterable, Hashable {
    case income
    case expense
}

enum RecurrenceInterval: String, Codable, Sendable, CaseIterable, Hashable {
    case weekly
    case monthly
    case yearly
}

@Model
final class Transaction {
    var id: UUID
    var type: TransactionType
    var category: Category?
    var amount: Double
    var currency: String
    var date: Date
    var descriptionText: String?
    var paymentMethod: String?
    var isRecurring: Bool
    var recurrenceInterval: RecurrenceInterval?
    var tags: [String]?
    var createdAt: Date
    var updatedAt: Date?

    init(
        id: UUID = UUID(),
        type: TransactionType,
        category: Category? = nil,
        amount: Double,
        currency: String = AppConstants.defaultCurrency,
        date: Date = Date(),
        descriptionText: String? = nil,
        paymentMethod: String? = nil,
        isRecurring: Bool = false,
        recurrenceInterval: RecurrenceInterval? = nil,
        tags: [String]? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.category = category
        self.amount = amount
        self.currency = currency
        self.date = date
        self.descriptionText = descriptionText
        self.paymentMethod = paymentMethod
        self.isRecurring = isRecurring
        self.recurrenceInterval = recurrenceInterval
        self.tags = tags
        self.createdAt = createdAt
    }
}
