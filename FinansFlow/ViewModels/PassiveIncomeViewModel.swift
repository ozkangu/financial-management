import Foundation

@Observable
final class PassiveIncomeViewModel {
    var passiveIncomes: [PassiveIncome] = []
    var isLoading = false
    var errorMessage: String?

    private let service = SupabaseService.shared

    var totalMonthlyPassiveIncome: Double {
        passiveIncomes.reduce(0) { sum, income in sum + income.monthlyAmount }
    }

    func passiveIncomeRatio(totalIncome: Double) -> Double {
        guard totalIncome > 0 else { return 0 }
        return (totalMonthlyPassiveIncome / totalIncome) * 100
    }

    func loadPassiveIncomes(workspaceId: UUID) async {
        isLoading = true
        defer { isLoading = false }

        do {
            passiveIncomes = try await service.fetchAll(
                from: "passive_incomes",
                filters: [("workspace_id", workspaceId.uuidString)],
                orderBy: "created_at",
                ascending: false
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createPassiveIncome(
        workspaceId: UUID,
        userId: UUID,
        investmentId: UUID?,
        type: PassiveIncomeType,
        amount: Double,
        currency: String,
        frequency: PaymentFrequency,
        nextPaymentDate: Date?,
        description: String?
    ) async throws {
        struct NewPassiveIncome: Encodable {
            let workspace_id: String
            let user_id: String
            let investment_id: String?
            let type: String
            let amount: Double
            let currency: String
            let frequency: String
            let next_payment_date: String?
            let description: String?
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let new = NewPassiveIncome(
            workspace_id: workspaceId.uuidString,
            user_id: userId.uuidString,
            investment_id: investmentId?.uuidString,
            type: type.rawValue,
            amount: amount,
            currency: currency,
            frequency: frequency.rawValue,
            next_payment_date: nextPaymentDate.map { date in dateFormatter.string(from: date) },
            description: description
        )

        let created: PassiveIncome = try await service.insertReturning(into: "passive_incomes", value: new)
        passiveIncomes.insert(created, at: 0)
    }

    func updatePassiveIncome(_ income: PassiveIncome) async throws {
        struct UpdatePayload: Encodable {
            let investment_id: String?
            let type: String
            let amount: Double
            let frequency: String
            let next_payment_date: String?
            let description: String?
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        try await service.update(
            table: "passive_incomes",
            id: income.id,
            value: UpdatePayload(
                investment_id: income.investmentId?.uuidString,
                type: income.type.rawValue,
                amount: income.amount,
                frequency: income.frequency.rawValue,
                next_payment_date: income.nextPaymentDate.map { date in dateFormatter.string(from: date) },
                description: income.description
            )
        )

        if let index = passiveIncomes.firstIndex(where: { existingIncome in existingIncome.id == income.id }) {
            passiveIncomes[index] = income
        }
    }

    func deletePassiveIncome(_ income: PassiveIncome) async throws {
        try await service.delete(from: "passive_incomes", id: income.id)
        passiveIncomes.removeAll { existingIncome in existingIncome.id == income.id }
    }
}
