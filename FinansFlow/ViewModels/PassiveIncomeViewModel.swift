import Foundation
import SwiftData

@Observable
final class PassiveIncomeViewModel {
    var passiveIncomes: [PassiveIncome] = []
    var isLoading = false
    var errorMessage: String?

    var totalMonthlyPassiveIncome: Double {
        passiveIncomes.reduce(0) { $0 + $1.monthlyAmount }
    }

    func passiveIncomeRatio(totalIncome: Double) -> Double {
        guard totalIncome > 0 else { return 0 }
        return (totalMonthlyPassiveIncome / totalIncome) * 100
    }

    func loadPassiveIncomes(context: ModelContext) {
        isLoading = true
        defer { isLoading = false }

        do {
            let descriptor = FetchDescriptor<PassiveIncome>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
            passiveIncomes = try context.fetch(descriptor)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createPassiveIncome(
        context: ModelContext,
        investment: Investment?,
        type: PassiveIncomeType,
        amount: Double,
        currency: String,
        frequency: PaymentFrequency,
        nextPaymentDate: Date?,
        descriptionText: String?
    ) {
        let income = PassiveIncome(
            investment: investment,
            type: type,
            amount: amount,
            currency: currency,
            frequency: frequency,
            nextPaymentDate: nextPaymentDate,
            descriptionText: descriptionText
        )
        context.insert(income)
        try? context.save()
        passiveIncomes.insert(income, at: 0)
    }

    func updatePassiveIncome(_ income: PassiveIncome, context: ModelContext) {
        try? context.save()
    }

    func deletePassiveIncome(_ income: PassiveIncome, context: ModelContext) {
        context.delete(income)
        try? context.save()
        passiveIncomes.removeAll { $0.id == income.id }
    }
}
