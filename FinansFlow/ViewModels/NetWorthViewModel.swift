import Foundation
import SwiftData

@Observable
final class NetWorthViewModel {
    var assets: [Asset] = []
    var snapshots: [NetWorthSnapshot] = []
    var isLoading = false
    var errorMessage: String?

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

    func loadAssets(context: ModelContext) {
        isLoading = true
        defer { isLoading = false }

        do {
            let descriptor = FetchDescriptor<Asset>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
            assets = try context.fetch(descriptor)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadSnapshots(context: ModelContext) {
        do {
            let descriptor = FetchDescriptor<NetWorthSnapshot>(sortBy: [SortDescriptor(\.date)])
            snapshots = try context.fetch(descriptor)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createAsset(
        context: ModelContext,
        name: String,
        type: AssetType,
        value: Double,
        currency: String,
        notes: String?
    ) {
        let asset = Asset(
            name: name,
            type: type,
            value: value,
            currency: currency,
            notes: notes
        )
        context.insert(asset)
        try? context.save()
        assets.insert(asset, at: 0)
    }

    func updateAsset(_ asset: Asset, context: ModelContext) {
        asset.updatedAt = Date()
        try? context.save()
    }

    func deleteAsset(_ asset: Asset, context: ModelContext) {
        context.delete(asset)
        try? context.save()
        assets.removeAll { $0.id == asset.id }
    }

    func createSnapshot(context: ModelContext, totalLiabilities: Double) {
        let netWorth = totalAssets - totalLiabilities
        let snapshot = NetWorthSnapshot(
            totalAssets: totalAssets,
            totalLiabilities: totalLiabilities,
            netWorth: netWorth
        )
        context.insert(snapshot)
        try? context.save()
        loadSnapshots(context: context)
    }
}
