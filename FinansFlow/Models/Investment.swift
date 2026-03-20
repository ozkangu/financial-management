import Foundation

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

struct Investment: Codable, Identifiable, Sendable {
    let id: UUID
    let workspaceId: UUID
    let userId: UUID
    var name: String
    var type: InvestmentType
    var purchaseDate: Date?
    var unitCost: Double
    var quantity: Double
    var currentValue: Double
    var currency: String
    var institution: String?
    var notes: String?
    let createdAt: Date?
    var updatedAt: Date?

    var totalCost: Double {
        unitCost * quantity
    }

    var profitLoss: Double {
        currentValue - totalCost
    }

    var profitLossPercentage: Double {
        guard totalCost > 0 else { return 0 }
        return (profitLoss / totalCost) * 100
    }

    enum CodingKeys: String, CodingKey {
        case id, name, type, quantity, currency, institution, notes
        case workspaceId = "workspace_id"
        case userId = "user_id"
        case purchaseDate = "purchase_date"
        case unitCost = "unit_cost"
        case currentValue = "current_value"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
