import SwiftUI
import Charts

struct InvestmentListView: View {
    @Bindable var viewModel: InvestmentViewModel
    let workspaceId: UUID

    @State private var showAddSheet = false
    @State private var editingInvestment: Investment?

    init(viewModel: InvestmentViewModel = InvestmentViewModel(),
         workspaceId: UUID = UUID()) {
        self.viewModel = viewModel
        self.workspaceId = workspaceId
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Portfolio Summary
                    portfolioSummary

                    // Distribution Chart
                    distributionChart

                    // Investment List
                    investmentList
                }
                .padding(.vertical)
            }
            .navigationTitle("Yatırımlar")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                InvestmentFormView(viewModel: viewModel, workspaceId: workspaceId)
            }
            .sheet(item: $editingInvestment) { inv in
                InvestmentFormView(viewModel: viewModel, workspaceId: workspaceId, editingInvestment: inv)
            }
            .task {
                await viewModel.loadInvestments(workspaceId: workspaceId)
            }
        }
    }

    private var portfolioSummary: some View {
        VStack(spacing: 8) {
            Text("TOPLAM PORTFÖY")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(viewModel.totalPortfolioValue.formatted())
                .font(.title.bold())
            HStack(spacing: 16) {
                VStack {
                    Text("Maliyet")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(viewModel.totalCost.formatted())
                        .font(.subheadline)
                }
                VStack {
                    Text("Kar/Zarar")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(viewModel.totalProfitLoss.formatted())
                        .font(.subheadline.bold())
                        .foregroundStyle(viewModel.totalProfitLoss >= 0 ? .green : .red)
                }
                VStack {
                    Text("Getiri")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(viewModel.totalProfitLossPercentage.percentFormatted)
                        .font(.subheadline.bold())
                        .foregroundStyle(viewModel.totalProfitLoss >= 0 ? .green : .red)
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

    private var distributionChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("DAĞILIM")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            let dist = viewModel.distributionByType
            if dist.isEmpty {
                Text("Henüz yatırım yok")
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
                    .annotation(position: .overlay) {
                        if item.percentage > 8 {
                            Text("\(Int(item.percentage))%")
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                        }
                    }
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

    private var investmentList: some View {
        Group {
            if viewModel.investments.isEmpty {
                EmptyStateView(
                    icon: "chart.pie.fill",
                    title: "Henüz Yatırım Yok",
                    description: "Portföyünüze ilk yatırımınızı ekleyin",
                    actionTitle: "Yatırım Ekle"
                ) {
                    showAddSheet = true
                }
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(viewModel.investments) { inv in
                        InvestmentRowView(investment: inv)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                HapticManager.selection()
                                editingInvestment = inv
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    Task {
                                        try? await viewModel.deleteInvestment(inv)
                                        HapticManager.notification(.success)
                                    }
                                } label: {
                                    Label("Sil", systemImage: "trash")
                                }
                            }
                        if inv.id != viewModel.investments.last?.id {
                            Divider().padding(.leading, 52)
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
    }
}

struct InvestmentRowView: View {
    let investment: Investment

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: investment.type.icon)
                .font(.title3)
                .frame(width: 36, height: 36)
                .background(Color.accentColor.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(investment.name)
                    .font(.subheadline.weight(.medium))
                Text(investment.type.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(investment.currentValue.formatted())
                    .font(.subheadline.bold())
                HStack(spacing: 2) {
                    Text(investment.profitLoss.formatted())
                    Text("(\(investment.profitLossPercentage.percentFormatted))")
                }
                .font(.caption)
                .foregroundStyle(investment.profitLoss >= 0 ? .green : .red)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(investment.name), \(investment.type.displayName), \(String(localized: "değer:")) \(investment.currentValue.formatted())")
    }
}

#Preview {
    InvestmentListView()
}
