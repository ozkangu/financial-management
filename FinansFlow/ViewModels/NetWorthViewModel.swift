import Foundation

@Observable
final class NetWorthViewModel {
    var assets: [Asset] = []
    var snapshots: [NetWorthSnapshot] = []
    var isLoading = false
    var errorMessage: String?

    private let service = SupabaseService.shared
    private var latestAssetsWorkspaceId: UUID?
    private var latestSnapshotsWorkspaceId: UUID?

    var totalAssets: Double {
        assets.reduce(0) { $0 + $1.value }
    }

    var assetDistribution: [(type: AssetType, value: Double, percentage: Double)] {
        let grouped = Dictionary(grouping: assets) { $0.type }
        let total = totalAssets
        guard total > 0 else { return [] }
        return grouped.map { (type, items) in
            let value = items.reduce(0.0) { $0 + $1.value }
            return (type: type, value: value, percentage: (value / total) * 100)
        }
        .sorted { $0.value > $1.value }
    }

    func loadAssets(workspaceId: UUID) async {
        latestAssetsWorkspaceId = workspaceId
        isLoading = true
        defer {
            if latestAssetsWorkspaceId == workspaceId {
                isLoading = false
            }
        }

        do {
            let fetched: [Asset] = try await service.fetchAll(
                from: "assets",
                filters: [("workspace_id", workspaceId.uuidString)],
                orderBy: "created_at",
                ascending: false
            )
            guard latestAssetsWorkspaceId == workspaceId else { return }
            assets = fetched
        } catch {
            guard latestAssetsWorkspaceId == workspaceId else { return }
            errorMessage = error.localizedDescription
        }
    }

    func loadSnapshots(workspaceId: UUID) async {
        latestSnapshotsWorkspaceId = workspaceId
        do {
            let fetched: [NetWorthSnapshot] = try await service.fetchAll(
                from: "net_worth_snapshots",
                filters: [("workspace_id", workspaceId.uuidString)],
                orderBy: "date",
                ascending: true
            )
            guard latestSnapshotsWorkspaceId == workspaceId else { return }
            snapshots = fetched
        } catch {
            guard latestSnapshotsWorkspaceId == workspaceId else { return }
            errorMessage = error.localizedDescription
        }
    }

    func createAsset(
        workspaceId: UUID,
        userId: UUID,
        name: String,
        type: AssetType,
        value: Double,
        currency: String,
        notes: String?
    ) async throws {
        struct NewAsset: Encodable {
            let workspace_id: String
            let user_id: String
            let name: String
            let type: String
            let value: Double
            let currency: String
            let notes: String?
        }

        let created: Asset = try await service.insertReturning(
            into: "assets",
            value: NewAsset(
                workspace_id: workspaceId.uuidString,
                user_id: userId.uuidString,
                name: name,
                type: type.rawValue,
                value: value,
                currency: currency,
                notes: notes
            )
        )
        assets.insert(created, at: 0)
    }

    func updateAsset(_ asset: Asset) async throws {
        struct UpdatePayload: Encodable {
            let name: String
            let type: String
            let value: Double
            let notes: String?
        }

        try await service.update(
            table: "assets",
            id: asset.id,
            value: UpdatePayload(
                name: asset.name,
                type: asset.type.rawValue,
                value: asset.value,
                notes: asset.notes
            )
        )

        if let idx = assets.firstIndex(where: { $0.id == asset.id }) {
            assets[idx] = asset
        }
    }

    func deleteAsset(_ asset: Asset) async throws {
        try await service.delete(from: "assets", id: asset.id)
        assets.removeAll { $0.id == asset.id }
    }

    func createSnapshot(workspaceId: UUID, totalLiabilities: Double) async throws {
        struct NewSnapshot: Encodable {
            let workspace_id: String
            let date: String
            let total_assets: Double
            let total_liabilities: Double
            let net_worth: Double
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let netWorth = totalAssets - totalLiabilities
        try await service.insert(
            into: "net_worth_snapshots",
            value: NewSnapshot(
                workspace_id: workspaceId.uuidString,
                date: dateFormatter.string(from: Date()),
                total_assets: totalAssets,
                total_liabilities: totalLiabilities,
                net_worth: netWorth
            )
        )
        await loadSnapshots(workspaceId: workspaceId)
    }
}
