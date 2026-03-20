import Foundation
import SwiftData

enum InvestmentType: String, Codable, Sendable, CaseIterable {
    case stock
    case fundEtf = "fund_etf"
    case gold
    case forex
    case crypto
    case realEstate = "real_estate"
    case deposit
    case retirement
    case bond
    case other

    var displayName: String {
        switch self {
        case .stock: return String(localized: "Hisse Senedi")
        case .fundEtf: return String(localized: "Fon/ETF")
        case .gold: return String(localized: "Altın")
        case .forex: return String(localized: "Döviz")
        case .crypto: return String(localized: "Kripto")
        case .realEstate: return String(localized: "Gayrimenkul")
        case .deposit: return String(localized: "Mevduat")
        case .retirement: return String(localized: "BES")
        case .bond: return String(localized: "Tahvil/Bono")
        case .other: return String(localized: "Diğer")
        }
    }

    var icon: String {
        switch self {
        case .stock: return "chart.line.uptrend.xyaxis"
        case .fundEtf: return "chart.pie.fill"
        case .gold: return "circle.fill"
        case .forex: return "dollarsign.circle.fill"
        case .crypto: return "bitcoinsign.circle.fill"
        case .realEstate: return "house.fill"
        case .deposit: return "banknote.fill"
        case .retirement: return "person.fill"
        case .bond: return "doc.text.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

@Model
final class Investment {
    var id: UUID
    var name: String
    var type: InvestmentType
    var purchaseDate: Date?
    var unitCost: Double
    var quantity: Double
    var currentValue: Double
    var currency: String
    var institution: String?
    var notes: String?
    @Relationship(deleteRule: .nullify, inverse: \PassiveIncome.investment)
    var passiveIncomes: [PassiveIncome]
    var createdAt: Date
    var updatedAt: Date?

    var totalCost: Double {
        unitCost * quantity
    }

    var currentUnitPrice: Double {
        guard quantity > 0 else { return currentValue }
        return currentValue / quantity
    }

    var profitLoss: Double {
        currentValue - totalCost
    }

    var profitLossPercentage: Double {
        guard totalCost > 0 else { return 0 }
        return (profitLoss / totalCost) * 100
    }

    init(
        id: UUID = UUID(),
        name: String,
        type: InvestmentType,
        purchaseDate: Date? = nil,
        unitCost: Double = 0,
        quantity: Double = 0,
        currentValue: Double = 0,
        currency: String = AppConstants.defaultCurrency,
        institution: String? = nil,
        notes: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.purchaseDate = purchaseDate
        self.unitCost = unitCost
        self.quantity = quantity
        self.currentValue = currentValue
        self.currency = currency
        self.institution = institution
        self.notes = notes
        self.passiveIncomes = []
        self.createdAt = createdAt
    }
}
