import SwiftUI

struct LiabilityListView: View {
    @Bindable var viewModel: LiabilityViewModel
    let workspaceId: UUID

    @State private var showAddSheet = false
    @State private var editingLiability: Liability?

    var body: some View {
        List {
            // Summary section
            Section {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Toplam Borç")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(viewModel.totalDebt.formatted())
                            .font(.title2.bold())
                            .foregroundStyle(.red)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("Aylık Ödeme")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(viewModel.totalMonthlyPayment.formatted())
                            .font(.title2.bold())
                    }
                }
                .padding(.vertical, 4)
            }

            // Liability list
            if viewModel.liabilities.isEmpty {
                Section {
                    EmptyStateView(
                        icon: "creditcard.fill",
                        title: "Henüz Borç Kaydı Yok",
                        description: "Kredi, kredi kartı veya diğer borçlarınızı ekleyin",
                        actionTitle: "Borç Ekle"
                    ) {
                        showAddSheet = true
                    }
                    .listRowBackground(Color.clear)
                }
            } else {
                Section("Borçlar") {
                    ForEach(viewModel.liabilities) { liability in
                        LiabilityRowView(liability: liability)
                            .onTapGesture {
                                HapticManager.selection()
                                editingLiability = liability
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    Task {
                                        try? await viewModel.deleteLiability(liability)
                                        HapticManager.notification(.success)
                                    }
                                } label: {
                                    Label("Sil", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
        .navigationTitle("Borçlar")
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
            LiabilityFormView(viewModel: viewModel, workspaceId: workspaceId)
        }
        .sheet(item: $editingLiability) { liability in
            LiabilityFormView(viewModel: viewModel, workspaceId: workspaceId, editingLiability: liability)
        }
        .task {
            await viewModel.loadLiabilities(workspaceId: workspaceId)
        }
    }
}

struct LiabilityRowView: View {
    let liability: Liability

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: liability.type.icon)
                    .font(.title3)
                    .frame(width: 36, height: 36)
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

                VStack(alignment: .trailing, spacing: 2) {
                    Text(liability.remainingAmount.formatted())
                        .font(.subheadline.bold())
                    if let payment = liability.monthlyPayment {
                        Text("\(payment.formatted())/ay")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Progress bar
            ProgressView(value: liability.paidPercentage, total: 100)
                .tint(.green)

            HStack {
                Text("Ödenen: %\(Int(liability.paidPercentage))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                if let dueDate = liability.dueDate {
                    Text("Son: \(dueDate.displayString)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(liability.name), \(liability.type.displayName), \(String(localized: "kalan:")) \(liability.remainingAmount.formatted())")
    }
}
