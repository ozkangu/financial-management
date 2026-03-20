import Foundation

@Observable
final class LiabilityViewModel {
    var liabilities: [Liability] = []
    var isLoading = false
    var errorMessage: String?

    private let service = SupabaseService.shared
    private var latestWorkspaceId: UUID?

    var totalDebt: Double {
        liabilities.reduce(0) { $0 + $1.remainingAmount }
    }

    var totalMonthlyPayment: Double {
        liabilities.reduce(0) { $0 + ($1.monthlyPayment ?? 0) }
    }

    func loadLiabilities(workspaceId: UUID) async {
        latestWorkspaceId = workspaceId
        isLoading = true
        defer {
            if latestWorkspaceId == workspaceId {
                isLoading = false
            }
        }

        do {
            let fetched: [Liability] = try await service.fetchAll(
                from: "liabilities",
                filters: [("workspace_id", workspaceId.uuidString)],
                orderBy: "created_at",
                ascending: false
            )
            guard latestWorkspaceId == workspaceId else { return }
            liabilities = fetched
        } catch {
            guard latestWorkspaceId == workspaceId else { return }
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
            due_date: dueDate.map { dateFormatter.string(from: $0) },
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
                due_date: liability.dueDate.map { dateFormatter.string(from: $0) },
                notes: liability.notes
            )
        )

        if let idx = liabilities.firstIndex(where: { $0.id == liability.id }) {
            liabilities[idx] = liability
        }
    }

    func deleteLiability(_ liability: Liability) async throws {
        try await service.delete(from: "liabilities", id: liability.id)
        liabilities.removeAll { $0.id == liability.id }
    }
}
