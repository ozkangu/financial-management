import Foundation
import SwiftData

enum AssetType: String, Codable, Sendable, CaseIterable {
    case bankAccount = "bank_account"
    case cash
    case investment
    case realEstate = "real_estate"
    case vehicle
    case receivable
    case other

    var displayName: String {
        switch self {
        case .bankAccount: return String(localized: "Banka Hesabı")
        case .cash: return String(localized: "Nakit")
        case .investment: return String(localized: "Yatırım")
        case .realEstate: return String(localized: "Gayrimenkul")
        case .vehicle: return String(localized: "Araç")
        case .receivable: return String(localized: "Alacak")
        case .other: return String(localized: "Diğer")
        }
    }

    var icon: String {
        switch self {
        case .bankAccount: return "building.columns.fill"
        case .cash: return "banknote.fill"
        case .investment: return "chart.line.uptrend.xyaxis"
        case .realEstate: return "house.fill"
        case .vehicle: return "car.fill"
        case .receivable: return "person.fill.checkmark"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

@Model
final class Asset {
    var id: UUID
    var name: String
    var type: AssetType
    var value: Double
    var currency: String
    var notes: String?
    var createdAt: Date
    var updatedAt: Date?

    init(
        id: UUID = UUID(),
        name: String,
        type: AssetType,
        value: Double,
        currency: String = AppConstants.defaultCurrency,
        notes: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.value = value
        self.currency = currency
        self.notes = notes
        self.createdAt = createdAt
    }
}
