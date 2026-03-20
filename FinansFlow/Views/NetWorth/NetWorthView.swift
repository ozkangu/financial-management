import SwiftUI
import Charts
import SwiftData

struct NetWorthView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var netWorthVM: NetWorthViewModel
    @Bindable var liabilityVM: LiabilityViewModel
    @Bindable var investmentVM: InvestmentViewModel

    @State private var showAddAsset = false
    @State private var editingAsset: Asset?

    init(
        netWorthVM: NetWorthViewModel = NetWorthViewModel(),
        liabilityVM: LiabilityViewModel = LiabilityViewModel(),
        investmentVM: InvestmentViewModel = InvestmentViewModel()
    ) {
        self.netWorthVM = netWorthVM
        self.liabilityVM = liabilityVM
        self.investmentVM = investmentVM
    }

    private var netWorth: Double {
        netWorthVM.totalAssets - liabilityVM.totalDebt
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    netWorthSummary
                    wealthStructureNotice
                    assetDistributionChart
                    investmentPortfolioSection
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
            .navigationTitle("Servet")
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

    private var wealthStructureNotice: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Servet Yapısı")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text("Bu ekran yatırım portföyünüzü, diğer varlıklarınızı ve borçlarınızı tek yerden toplar. Net varlık hesabı şu anda yatırım dışı varlıklar ve borçlar üzerinden ilerler.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.accentColor.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
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

    private var investmentPortfolioSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("YATIRIM PORTFÖYÜ")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text("Yatırımlar ayrı sekme yerine burada özetlenir.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                NavigationLink {
                    InvestmentListView(viewModel: investmentVM)
                } label: {
                    Text("Tümünü Gör")
                        .font(.caption.weight(.semibold))
                }
            }

            if investmentVM.investments.isEmpty {
                Text("Henüz yatırım yok")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            } else {
                HStack(spacing: 16) {
                    miniMetric(
                        title: "Portföy",
                        value: investmentVM.totalPortfolioValue.formatted(),
                        color: .primary
                    )
                    miniMetric(
                        title: "Kar/Zarar",
                        value: investmentVM.totalProfitLoss.formatted(),
                        color: investmentVM.totalProfitLoss >= 0 ? .green : .red
                    )
                    miniMetric(
                        title: "Getiri",
                        value: investmentVM.totalProfitLossPercentage.percentFormatted,
                        color: investmentVM.totalProfitLoss >= 0 ? .green : .red
                    )
                }

                VStack(spacing: 0) {
                    ForEach(Array(investmentVM.investments.prefix(3))) { investment in
                        InvestmentRowView(investment: investment)
                        if investment.id != investmentVM.investments.prefix(3).last?.id {
                            Divider().padding(.leading, 48)
                        }
                    }
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

    private func miniMetric(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.bold())
                .foregroundStyle(color)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    NetWorthView()
        .modelContainer(for: [Asset.self, Liability.self, NetWorthSnapshot.self, Investment.self, PassiveIncome.self], inMemory: true)
}
