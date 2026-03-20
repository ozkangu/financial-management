import SwiftUI

struct PassiveIncomeListView: View {
    @Bindable var viewModel: PassiveIncomeViewModel
    @Bindable var investmentVM: InvestmentViewModel
    let workspaceId: UUID
    var totalMonthlyIncome: Double = 0

    @State private var showAddSheet = false
    @State private var editingIncome: PassiveIncome?

    var body: some View {
        List {
            Section {
                VStack(spacing: 8) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Aylık Pasif Gelir")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(viewModel.totalMonthlyPassiveIncome.formatted())
                                .font(.title2.bold())
                                .foregroundStyle(.green)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("Pasif Gelir Oranı")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(viewModel.passiveIncomeRatio(totalIncome: totalMonthlyIncome).percentFormatted)
                                .font(.title2.bold())
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Pasif Gelirler") {
                ForEach(viewModel.passiveIncomes) { income in
                    PassiveIncomeRowView(
                        income: income,
                        investmentName: investmentVM.investments.first { $0.id == income.investmentId }?.name
                    )
                    .onTapGesture { editingIncome = income }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            Task { try? await viewModel.deletePassiveIncome(income) }
                        } label: {
                            Label("Sil", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .navigationTitle("Pasif Gelirler")
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
            PassiveIncomeFormView(
                viewModel: viewModel,
                investmentVM: investmentVM,
                workspaceId: workspaceId
            )
        }
        .sheet(item: $editingIncome) { income in
            PassiveIncomeFormView(
                viewModel: viewModel,
                investmentVM: investmentVM,
                workspaceId: workspaceId,
                editingIncome: income
            )
        }
        .task {
            await viewModel.loadPassiveIncomes(workspaceId: workspaceId)
        }
    }
}

struct PassiveIncomeRowView: View {
    let income: PassiveIncome
    let investmentName: String?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: income.type.icon)
                .font(.title3)
                .frame(width: 36, height: 36)
                .background(Color.green.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(income.description ?? income.type.displayName)
                    .font(.subheadline.weight(.medium))
                HStack {
                    Text(income.type.displayName)
                    if let invName = investmentName {
                        Text("/ \(invName)")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("+\(income.amount.formatted())")
                    .font(.subheadline.bold())
                    .foregroundStyle(.green)
                Text(income.frequency.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .contentShape(Rectangle())
    }
}
