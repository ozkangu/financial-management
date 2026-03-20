import Foundation
import SwiftData

enum PassiveIncomeType: String, Codable, Sendable, CaseIterable {
    case dividend
    case interest
    case rent
    case staking
    case coupon
    case other

    var displayName: String {
        switch self {
        case .dividend: return String(localized: "Temettü")
        case .interest: return String(localized: "Faiz")
        case .rent: return String(localized: "Kira")
        case .staking: return String(localized: "Staking")
        case .coupon: return String(localized: "Kupon")
        case .other: return String(localized: "Diğer")
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
        case .monthly: return String(localized: "Aylık")
        case .quarterly: return String(localized: "Çeyreklik")
        case .yearly: return String(localized: "Yıllık")
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

@Model
final class PassiveIncome {
    var id: UUID
    var investment: Investment?
    var type: PassiveIncomeType
    var amount: Double
    var currency: String
    var frequency: PaymentFrequency
    var nextPaymentDate: Date?
    var descriptionText: String?
    var createdAt: Date

    var monthlyAmount: Double {
        amount * frequency.monthlyMultiplier
    }

    init(
        id: UUID = UUID(),
        investment: Investment? = nil,
        type: PassiveIncomeType,
        amount: Double,
        currency: String = AppConstants.defaultCurrency,
        frequency: PaymentFrequency = .monthly,
        nextPaymentDate: Date? = nil,
        descriptionText: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.investment = investment
        self.type = type
        self.amount = amount
        self.currency = currency
        self.frequency = frequency
        self.nextPaymentDate = nextPaymentDate
        self.descriptionText = descriptionText
        self.createdAt = createdAt
    }
}
