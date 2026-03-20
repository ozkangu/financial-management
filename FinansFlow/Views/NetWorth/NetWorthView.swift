import SwiftUI
import Charts
import SwiftData

struct NetWorthView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var netWorthVM: NetWorthViewModel
    @Bindable var liabilityVM: LiabilityViewModel

    @State private var showAddAsset = false
    @State private var editingAsset: Asset?

    init(netWorthVM: NetWorthViewModel = NetWorthViewModel(),
         liabilityVM: LiabilityViewModel = LiabilityViewModel()) {
        self.netWorthVM = netWorthVM
        self.liabilityVM = liabilityVM
    }

    private var netWorth: Double {
        netWorthVM.totalAssets - liabilityVM.totalDebt
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    netWorthSummary
                    assetDistributionChart
                    trendChart
                    assetsSection
                    liabilitiesSection

                    Button {
                        HapticManager.impact(.medium)
                        netWorthVM.createSnapshot(
                            context: modelContext,
                            totalLiabilities: liabilityVM.totalDebt
                        )
                        HapticManager.notification(.success)
                    } label: {
                        Label("Snapshot Kaydet", systemImage: "camera.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .padding(.horizontal)
                    .accessibilityLabel(String(localized: "Net varlık snapshot'ı kaydet"))
                }
                .padding(.vertical)
            }
            .navigationTitle("Net Varlık")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddAsset = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddAsset) {
                AssetFormView(viewModel: netWorthVM)
            }
            .sheet(item: $editingAsset) { asset in
                AssetFormView(viewModel: netWorthVM, editingAsset: asset)
            }
        }
    }

    private var netWorthSummary: some View {
        VStack(spacing: 12) {
            Text("NET VARLIK")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(netWorth.formatted())
                .font(.largeTitle.bold())
                .foregroundStyle(netWorth >= 0 ? Color.primary : Color.red)

            HStack(spacing: 24) {
                VStack {
                    Text("Varlıklar")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(netWorthVM.totalAssets.formatted())
                        .font(.subheadline.bold())
                        .foregroundStyle(.green)
                }
                VStack {
                    Text("Borçlar")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(liabilityVM.totalDebt.formatted())
                        .font(.subheadline.bold())
                        .foregroundStyle(.red)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        .padding(.horizontal)
    }

    private var assetDistributionChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("VARLIK DAĞILIMI")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            let dist = netWorthVM.assetDistribution
            if dist.isEmpty {
                Text("Henüz varlık yok")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .frame(height: 150)
                    .frame(maxWidth: .infinity)
            } else {
                Chart(dist, id: \.type) { item in
                    SectorMark(
                        angle: .value("Değer", item.value),
                        innerRadius: .ratio(0.6),
                        angularInset: 1
                    )
                    .foregroundStyle(by: .value("Tür", item.type.displayName))
                }
                .frame(height: 150)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        .padding(.horizontal)
    }

    private var trendChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("NET VARLIK TRENDİ")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            if netWorthVM.snapshots.isEmpty {
                Text("Snapshot kaydı yok")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .frame(height: 150)
                    .frame(maxWidth: .infinity)
            } else {
                Chart(netWorthVM.snapshots) { snapshot in
                    LineMark(
                        x: .value("Tarih", snapshot.date),
                        y: .value("Net Varlık", snapshot.netWorth)
                    )
                    .foregroundStyle(Color.accentColor)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Tarih", snapshot.date),
                        y: .value("Net Varlık", snapshot.netWorth)
                    )
                    .foregroundStyle(
                        .linearGradient(
                            colors: [Color.accentColor.opacity(0.2), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                .frame(height: 150)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        .padding(.horizontal)
    }

    private var assetsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("VARLIKLAR")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            if netWorthVM.assets.isEmpty {
                EmptyStateView(
                    icon: "building.columns.fill",
                    title: "Henüz Varlık Yok",
                    description: "Gayrimenkul, araç veya diğer varlıklarınızı ekleyin",
                    actionTitle: "Varlık Ekle"
                ) {
                    showAddAsset = true
                }
            }

            ForEach(netWorthVM.assets) { asset in
                HStack(spacing: 12) {
                    Image(systemName: asset.type.icon)
                        .font(.title3)
                        .frame(width: 32, height: 32)
                        .background(Color.green.opacity(0.15))
                        .clipShape(Circle())
                    VStack(alignment: .leading, spacing: 2) {
                        Text(asset.name)
                            .font(.subheadline.weight(.medium))
                        Text(asset.type.displayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(asset.value.formatted())
                        .font(.subheadline.bold())
                }
                .contentShape(Rectangle())
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(asset.name), \(asset.type.displayName), \(asset.value.formatted())")
                .onTapGesture {
                    HapticManager.selection()
                    editingAsset = asset
                }
                .contextMenu {
                    Button(role: .destructive) {
                        netWorthVM.deleteAsset(asset, context: modelContext)
                    } label: {
                        Label("Sil", systemImage: "trash")
                    }
                }
                if asset.id != netWorthVM.assets.last?.id {
                    Divider().padding(.leading, 44)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        .padding(.horizontal)
    }

    private var liabilitiesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("BORÇLAR")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            ForEach(liabilityVM.liabilities) { liability in
                HStack(spacing: 12) {
                    Image(systemName: liability.type.icon)
                        .font(.title3)
                        .frame(width: 32, height: 32)
                        .background(Color.red.opacity(0.15))
                        .clipShape(Circle())
                    VStack(alignment: .leading, spacing: 2) {
                        Text(liability.name)
                            .font(.subheadline.weight(.medium))
                        Text(liability.type.displayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(liability.remainingAmount.formatted())
                        .font(.subheadline.bold())
                        .foregroundStyle(.red)
                }
                if liability.id != liabilityVM.liabilities.last?.id {
                    Divider().padding(.leading, 44)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        .padding(.horizontal)
    }
}

#Preview {
    NetWorthView()
        .modelContainer(for: [Asset.self, Liability.self, NetWorthSnapshot.self], inMemory: true)
}
