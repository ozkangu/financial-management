import Foundation

@Observable
final class InvestmentViewModel {
    var investments: [Investment] = []
    var isLoading = false
    var errorMessage: String?

    private let service = SupabaseService.shared

    var totalPortfolioValue: Double {
        investments.reduce(0) { sum, investment in sum + investment.currentValue }
    }

    var totalCost: Double {
        investments.reduce(0) { sum, investment in sum + investment.totalCost }
    }

    var totalProfitLoss: Double {
        totalPortfolioValue - totalCost
    }

    var totalProfitLossPercentage: Double {
        guard totalCost > 0 else { return 0 }
        return (totalProfitLoss / totalCost) * 100
    }

    var distributionByType: [(type: InvestmentType, value: Double, percentage: Double)] {
        let grouped = Dictionary(grouping: investments) { investment in investment.type }
        let total = totalPortfolioValue
        guard total > 0 else { return [] }
        return grouped.map { investmentType, investmentItems in
            let value = investmentItems.reduce(0.0) { sum, investment in sum + investment.currentValue }
            return (type: investmentType, value: value, percentage: (value / total) * 100)
        }
        .sorted { firstDistribution, secondDistribution in firstDistribution.value > secondDistribution.value }
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
            purchase_date: purchaseDate.map { date in dateFormatter.string(from: date) },
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

        if let index = investments.firstIndex(where: { existingInvestment in existingInvestment.id == investment.id }) {
            investments[index] = investment
        }
    }

    func deleteInvestment(_ investment: Investment) async throws {
        try await service.delete(from: "investments", id: investment.id)
        investments.removeAll { existingInvestment in existingInvestment.id == investment.id }
    }
}
