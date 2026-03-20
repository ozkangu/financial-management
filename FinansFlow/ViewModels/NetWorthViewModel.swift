import Foundation

@Observable
final class NetWorthViewModel {
    var assets: [Asset] = []
    var snapshots: [NetWorthSnapshot] = []
    var isLoading = false
    var errorMessage: String?

    private let service = SupabaseService.shared

    var totalAssets: Double {
        assets.reduce(0) { sum, asset in sum + asset.value }
    }

    var assetDistribution: [(type: AssetType, value: Double, percentage: Double)] {
        let grouped = Dictionary(grouping: assets) { asset in asset.type }
        let total = totalAssets
        guard total > 0 else { return [] }
        return grouped.map { assetType, assetItems in
            let value = assetItems.reduce(0.0) { sum, asset in sum + asset.value }
            return (type: assetType, value: value, percentage: (value / total) * 100)
        }
        .sorted { firstDistribution, secondDistribution in firstDistribution.value > secondDistribution.value }
    }

    func loadAssets(workspaceId: UUID) async {
        isLoading = true
        defer { isLoading = false }

        do {
            assets = try await service.fetchAll(
                from: "assets",
                filters: [("workspace_id", workspaceId.uuidString)],
                orderBy: "created_at",
                ascending: false
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadSnapshots(workspaceId: UUID) async {
        do {
            snapshots = try await service.fetchAll(
                from: "net_worth_snapshots",
                filters: [("workspace_id", workspaceId.uuidString)],
                orderBy: "date",
                ascending: true
            )
        } catch {
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

        if let index = assets.firstIndex(where: { existingAsset in existingAsset.id == asset.id }) {
            assets[index] = asset
        }
    }

    func deleteAsset(_ asset: Asset) async throws {
        try await service.delete(from: "assets", id: asset.id)
        assets.removeAll { existingAsset in existingAsset.id == asset.id }
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
