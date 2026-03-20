import Foundation
import SwiftData

@Observable
final class LiabilityViewModel {
    var liabilities: [Liability] = []
    var isLoading = false
    var errorMessage: String?

    var totalDebt: Double {
        liabilities.reduce(0) { $0 + $1.remainingAmount }
    }

    var totalMonthlyPayment: Double {
        liabilities.reduce(0) { $0 + ($1.monthlyPayment ?? 0) }
    }

    func loadLiabilities(context: ModelContext) {
        isLoading = true
        defer { isLoading = false }

        do {
            let descriptor = FetchDescriptor<Liability>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
            liabilities = try context.fetch(descriptor)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createLiability(
        context: ModelContext,
        name: String,
        type: LiabilityType,
        totalAmount: Double,
        remainingAmount: Double,
        interestRate: Double?,
        monthlyPayment: Double?,
        currency: String,
        dueDate: Date?,
        notes: String?
    ) {
        let liability = Liability(
            name: name,
            type: type,
            totalAmount: totalAmount,
            remainingAmount: remainingAmount,
            interestRate: interestRate,
            monthlyPayment: monthlyPayment,
            currency: currency,
            dueDate: dueDate,
            notes: notes
        )
        context.insert(liability)
        try? context.save()
        liabilities.insert(liability, at: 0)
    }

    func updateLiability(_ liability: Liability, context: ModelContext) {
        liability.updatedAt = Date()
        try? context.save()
    }

    func deleteLiability(_ liability: Liability, context: ModelContext) {
        context.delete(liability)
        try? context.save()
        liabilities.removeAll { $0.id == liability.id }
    }
}
