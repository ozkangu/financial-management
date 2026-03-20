import Foundation

@Observable
final class InvestmentViewModel {
    var investments: [Investment] = []
    var isLoading = false
    var errorMessage: String?

    private let service = SupabaseService.shared

    var totalPortfolioValue: Double {
        investments.reduce(0) { $0 + $1.currentValue }
    }

    var totalCost: Double {
        investments.reduce(0) { $0 + $1.totalCost }
    }

    var totalProfitLoss: Double {
        totalPortfolioValue - totalCost
    }

    var totalProfitLossPercentage: Double {
        guard totalCost > 0 else { return 0 }
        return (totalProfitLoss / totalCost) * 100
    }

    var distributionByType: [(type: InvestmentType, value: Double, percentage: Double)] {
        let grouped = Dictionary(grouping: investments) { $0.type }
        let total = totalPortfolioValue
        guard total > 0 else { return [] }
        return grouped.map { (type, items) in
            let value = items.reduce(0.0) { $0 + $1.currentValue }
            return (type: type, value: value, percentage: (value / total) * 100)
        }
        .sorted { $0.value > $1.value }
    }

    func loadInvestments(workspaceId: UUID) async {
        isLoading = true
        defer { isLoading = false }

        do {
            investments = try await service.fetchAll(
                from: "investments",
                filters: [("workspace_id", workspaceId.uuidString)],
                orderBy: "created_at",
                ascending: false
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createInvestment(
        workspaceId: UUID,
        userId: UUID,
        name: String,
        type: InvestmentType,
        purchaseDate: Date?,
        unitCost: Double,
        quantity: Double,
        currentValue: Double,
        currency: String,
        institution: String?,
        notes: String?
    ) async throws {
        struct NewInvestment: Encodable {
            let workspace_id: String
            let user_id: String
            let name: String
            let type: String
            let purchase_date: String?
            let unit_cost: Double
            let quantity: Double
            let current_value: Double
            let currency: String
            let institution: String?
            let notes: String?
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let new = NewInvestment(
            workspace_id: workspaceId.uuidString,
            user_id: userId.uuidString,
            name: name,
            type: type.rawValue,
            purchase_date: purchaseDate.map { dateFormatter.string(from: $0) },
            unit_cost: unitCost,
            quantity: quantity,
            current_value: currentValue,
            currency: currency,
            institution: institution,
            notes: notes
        )

        let created: Investment = try await service.insertReturning(into: "investments", value: new)
        investments.insert(created, at: 0)
    }

    func updateInvestment(_ investment: Investment) async throws {
        struct UpdatePayload: Encodable {
            let name: String
            let type: String
            let unit_cost: Double
            let quantity: Double
            let current_value: Double
            let institution: String?
            let notes: String?
        }

        try await service.update(
            table: "investments",
            id: investment.id,
            value: UpdatePayload(
                name: investment.name,
                type: investment.type.rawValue,
                unit_cost: investment.unitCost,
                quantity: investment.quantity,
                current_value: investment.currentValue,
                institution: investment.institution,
                notes: investment.notes
            )
        )

        if let idx = investments.firstIndex(where: { $0.id == investment.id }) {
            investments[idx] = investment
        }
    }

    func deleteInvestment(_ investment: Investment) async throws {
        try await service.delete(from: "investments", id: investment.id)
        investments.removeAll { $0.id == investment.id }
    }
}
