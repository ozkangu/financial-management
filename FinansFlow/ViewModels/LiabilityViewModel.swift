import Foundation

@Observable
final class LiabilityViewModel {
    var liabilities: [Liability] = []
    var isLoading = false
    var errorMessage: String?

    private let service = SupabaseService.shared

    var totalDebt: Double {
        liabilities.reduce(0) { sum, liability in sum + liability.remainingAmount }
    }

    var totalMonthlyPayment: Double {
        liabilities.reduce(0) { sum, liability in sum + (liability.monthlyPayment ?? 0) }
    }

    func loadLiabilities(workspaceId: UUID) async {
        isLoading = true
        defer { isLoading = false }

        do {
            liabilities = try await service.fetchAll(
                from: "liabilities",
                filters: [("workspace_id", workspaceId.uuidString)],
                orderBy: "created_at",
                ascending: false
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createLiability(
        workspaceId: UUID,
        userId: UUID,
        name: String,
        type: LiabilityType,
        totalAmount: Double,
        remainingAmount: Double,
        interestRate: Double?,
        monthlyPayment: Double?,
        currency: String,
        dueDate: Date?,
        notes: String?
    ) async throws {
        struct NewLiability: Encodable {
            let workspace_id: String
            let user_id: String
            let name: String
            let type: String
            let total_amount: Double
            let remaining_amount: Double
            let interest_rate: Double?
            let monthly_payment: Double?
            let currency: String
            let due_date: String?
            let notes: String?
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let new = NewLiability(
            workspace_id: workspaceId.uuidString,
            user_id: userId.uuidString,
            name: name,
            type: type.rawValue,
            total_amount: totalAmount,
            remaining_amount: remainingAmount,
            interest_rate: interestRate,
            monthly_payment: monthlyPayment,
            currency: currency,
            due_date: dueDate.map { date in dateFormatter.string(from: date) },
            notes: notes
        )

        let created: Liability = try await service.insertReturning(into: "liabilities", value: new)
        liabilities.insert(created, at: 0)
    }

    func updateLiability(_ liability: Liability) async throws {
        struct UpdatePayload: Encodable {
            let name: String
            let type: String
            let total_amount: Double
            let remaining_amount: Double
            let interest_rate: Double?
            let monthly_payment: Double?
            let due_date: String?
            let notes: String?
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        try await service.update(
            table: "liabilities",
            id: liability.id,
            value: UpdatePayload(
                name: liability.name,
                type: liability.type.rawValue,
                total_amount: liability.totalAmount,
                remaining_amount: liability.remainingAmount,
                interest_rate: liability.interestRate,
                monthly_payment: liability.monthlyPayment,
                due_date: liability.dueDate.map { date in dateFormatter.string(from: date) },
                notes: liability.notes
            )
        )

        if let index = liabilities.firstIndex(where: { existingLiability in existingLiability.id == liability.id }) {
            liabilities[index] = liability
        }
    }

    func deleteLiability(_ liability: Liability) async throws {
        try await service.delete(from: "liabilities", id: liability.id)
        liabilities.removeAll { existingLiability in existingLiability.id == liability.id }
    }
}
