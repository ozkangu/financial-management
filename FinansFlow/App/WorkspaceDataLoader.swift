import Foundation

struct WorkspaceDataLoader {
    let loadCategories: @Sendable (UUID) async -> Void
    let loadTransactions: @Sendable (UUID) async -> Void
    let loadInvestments: @Sendable (UUID) async -> Void
    let loadPassiveIncomes: @Sendable (UUID) async -> Void
    let loadLiabilities: @Sendable (UUID) async -> Void
    let loadAssets: @Sendable (UUID) async -> Void
    let loadSnapshots: @Sendable (UUID) async -> Void

    func reload(workspaceId: UUID) async {
        await loadCategories(workspaceId)
        await loadTransactions(workspaceId)
        await loadInvestments(workspaceId)
        await loadPassiveIncomes(workspaceId)
        await loadLiabilities(workspaceId)
        await loadAssets(workspaceId)
        await loadSnapshots(workspaceId)
    }
}
