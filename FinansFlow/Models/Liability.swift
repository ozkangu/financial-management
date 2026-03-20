import Foundation
import SwiftData

enum LiabilityType: String, Codable, Sendable, CaseIterable {
    case creditCard = "credit_card"
    case personalLoan = "personal_loan"
    case mortgage
    case autoLoan = "auto_loan"
    case personalDebt = "personal_debt"
    case other

    var displayName: String {
        switch self {
        case .creditCard: return String(localized: "Kredi Kartı")
        case .personalLoan: return String(localized: "İhtiyaç Kredisi")
        case .mortgage: return String(localized: "Konut Kredisi")
        case .autoLoan: return String(localized: "Araç Kredisi")
        case .personalDebt: return String(localized: "Şahsi Borç")
        case .other: return String(localized: "Diğer")
        }
    }

    var icon: String {
        switch self {
        case .creditCard: return "creditcard.fill"
        case .personalLoan: return "banknote.fill"
        case .mortgage: return "house.fill"
        case .autoLoan: return "car.fill"
        case .personalDebt: return "person.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

@Model
final class Liability {
    var id: UUID
    var name: String
    var type: LiabilityType
    var totalAmount: Double
    var remainingAmount: Double
    var interestRate: Double?
    var monthlyPayment: Double?
    var currency: String
    var dueDate: Date?
    var notes: String?
    var createdAt: Date
    var updatedAt: Date?

    var paidPercentage: Double {
        guard totalAmount > 0 else { return 0 }
        return ((totalAmount - remainingAmount) / totalAmount) * 100
    }

    init(
        id: UUID = UUID(),
        name: String,
        type: LiabilityType,
        totalAmount: Double,
        remainingAmount: Double,
        interestRate: Double? = nil,
        monthlyPayment: Double? = nil,
        currency: String = AppConstants.defaultCurrency,
        dueDate: Date? = nil,
        notes: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.totalAmount = totalAmount
        self.remainingAmount = remainingAmount
        self.interestRate = interestRate
        self.monthlyPayment = monthlyPayment
        self.currency = currency
        self.dueDate = dueDate
        self.notes = notes
        self.createdAt = createdAt
    }
}
