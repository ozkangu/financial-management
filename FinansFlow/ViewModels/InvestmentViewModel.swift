import Foundation
import SwiftData

@Observable
final class InvestmentViewModel {
    var investments: [Investment] = []
    var isLoading = false
    var errorMessage: String?

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

    func loadInvestments(context: ModelContext) {
        isLoading = true
        defer { isLoading = false }

        do {
            let descriptor = FetchDescriptor<Investment>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
            investments = try context.fetch(descriptor)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createInvestment(
        context: ModelContext,
        name: String,
        type: InvestmentType,
        purchaseDate: Date?,
        unitCost: Double,
        quantity: Double,
        currentValue: Double,
        currency: String,
        institution: String?,
        notes: String?
    ) {
        let investment = Investment(
            name: name,
            type: type,
            purchaseDate: purchaseDate,
            unitCost: unitCost,
            quantity: quantity,
            currentValue: currentValue,
            currency: currency,
            institution: institution,
            notes: notes
        )
        context.insert(investment)
        try? context.save()
        investments.insert(investment, at: 0)
    }

    func updateInvestment(_ investment: Investment, context: ModelContext) {
        investment.updatedAt = Date()
        try? context.save()
    }

    func deleteInvestment(_ investment: Investment, context: ModelContext) {
        context.delete(investment)
        try? context.save()
        investments.removeAll { $0.id == investment.id }
    }
}
