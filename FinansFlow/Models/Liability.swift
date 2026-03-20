import Foundation

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

struct Liability: Codable, Identifiable, Sendable {
    let id: UUID
    let workspaceId: UUID
    let userId: UUID
    var name: String
    var type: LiabilityType
    var totalAmount: Double
    var remainingAmount: Double
    var interestRate: Double?
    var monthlyPayment: Double?
    var currency: String
    var dueDate: Date?
    var notes: String?
    let createdAt: Date?
    var updatedAt: Date?

    var paidPercentage: Double {
        guard totalAmount > 0 else { return 0 }
        return ((totalAmount - remainingAmount) / totalAmount) * 100
    }

    enum CodingKeys: String, CodingKey {
        case id, name, type, currency, notes
        case workspaceId = "workspace_id"
        case userId = "user_id"
        case totalAmount = "total_amount"
        case remainingAmount = "remaining_amount"
        case interestRate = "interest_rate"
        case monthlyPayment = "monthly_payment"
        case dueDate = "due_date"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
