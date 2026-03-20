import Foundation

enum PassiveIncomeType: String, Codable, Sendable, CaseIterable {
    case dividend
    case interest
    case rent
    case staking
    case coupon
    case other

    var displayName: String {
        switch self {
        case .dividend: return "Temettü"
        case .interest: return "Faiz"
        case .rent: return "Kira"
        case .staking: return "Staking"
        case .coupon: return "Kupon"
        case .other: return "Diğer"
        }
    }

    var icon: String {
        switch self {
        case .dividend: return "chart.bar.fill"
        case .interest: return "percent"
        case .rent: return "house.fill"
        case .staking: return "bitcoinsign.circle.fill"
        case .coupon: return "ticket.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

enum PaymentFrequency: String, Codable, Sendable, CaseIterable {
    case monthly
    case quarterly
    case yearly

    var displayName: String {
        switch self {
        case .monthly: return "Aylık"
        case .quarterly: return "Çeyreklik"
        case .yearly: return "Yıllık"
        }
    }

    var monthlyMultiplier: Double {
        switch self {
        case .monthly: return 1
        case .quarterly: return 1.0 / 3.0
        case .yearly: return 1.0 / 12.0
        }
    }
}

struct PassiveIncome: Codable, Identifiable, Sendable {
    let id: UUID
    let workspaceId: UUID
    let userId: UUID
    var investmentId: UUID?
    var type: PassiveIncomeType
    var amount: Double
    var currency: String
    var frequency: PaymentFrequency
    var nextPaymentDate: Date?
    var description: String?
    let createdAt: Date?

    var monthlyAmount: Double {
        amount * frequency.monthlyMultiplier
    }

    enum CodingKeys: String, CodingKey {
        case id, type, amount, currency, frequency, description
        case workspaceId = "workspace_id"
        case userId = "user_id"
        case investmentId = "investment_id"
        case nextPaymentDate = "next_payment_date"
        case createdAt = "created_at"
    }
}
