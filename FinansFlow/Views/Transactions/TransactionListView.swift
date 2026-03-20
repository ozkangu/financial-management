import SwiftUI

struct TransactionListView: View {
    @Bindable var transactionVM: TransactionViewModel
    @Bindable var categoryVM: CategoryViewModel
    let workspaceId: UUID

    @State private var selectedType: TransactionType? = nil
    @State private var searchText = ""
    @State private var showAddIncome = false
    @State private var showAddExpense = false
    @State private var editingTransaction: Transaction?
    @State private var showFilter = false

    init(transactionVM: TransactionViewModel = TransactionViewModel(),
         categoryVM: CategoryViewModel = CategoryViewModel(),
         workspaceId: UUID = UUID()) {
        self.transactionVM = transactionVM
        self.categoryVM = categoryVM
        self.workspaceId = workspaceId
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Monthly summary
                MonthlySummaryCard(viewModel: transactionVM)
                    .padding()

                // Segmented control
                Picker("Tür", selection: $selectedType) {
                    Text("Tümü").tag(TransactionType?.none)
                    Text("Gelir").tag(TransactionType?.some(.income))
                    Text("Gider").tag(TransactionType?.some(.expense))
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Transaction list
                let filtered = transactionVM.filteredTransactions(
                    type: selectedType,
                    searchText: searchText
                )

                if filtered.isEmpty && !transactionVM.isLoading {
                    EmptyStateView(
                        icon: "tray.fill",
                        title: "Henüz İşlem Yok",
                        description: "İlk gelir veya gider kaydınızı oluşturun",
                        actionTitle: "İşlem Ekle"
                    ) {
                        showAddExpense = true
                    }
                } else {
                    List {
                        let grouped = Dictionary(grouping: filtered) { transaction in transaction.date.displayString }
                        let sortedDates = grouped.keys.sorted { firstDateKey, secondDateKey in
                            let firstTransactions = grouped[firstDateKey]!
                            let secondTransactions = grouped[secondDateKey]!
                            return (firstTransactions.first?.date ?? Date()) > (secondTransactions.first?.date ?? Date())
                        }

                        ForEach(sortedDates, id: \.self) { dateStr in
                            Section(dateStr) {
                                ForEach(grouped[dateStr] ?? []) { transaction in
                                    TransactionRowView(
                                        transaction: transaction,
                                        category: categoryVM.categories.first { existingCategory in existingCategory.id == transaction.categoryId }
                                    )
                                    .onTapGesture {
                                        HapticManager.selection()
                                        editingTransaction = transaction
                                    }
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            Task {
                                                try? await transactionVM.deleteTransaction(transaction)
                                                HapticManager.notification(.success)
                                            }
                                        } label: {
                                            Label("Sil", systemImage: "trash")
                                        }

                                        Button {
                                            editingTransaction = transaction
                                        } label: {
                                            Label("Düzenle", systemImage: "pencil")
                                        }
                                        .tint(.blue)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .searchable(text: $searchText, prompt: "İşlem ara...")
                    .refreshable {
                        await transactionVM.loadTransactions(workspaceId: workspaceId, reset: true)
                    }
                }
            }
            .navigationTitle("İşlemler")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showAddIncome = true
                        } label: {
                            Label("Gelir Ekle", systemImage: "plus.circle.fill")
                        }
                        Button {
                            showAddExpense = true
                        } label: {
                            Label("Gider Ekle", systemImage: "minus.circle.fill")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddIncome) {
                TransactionFormView(
                    viewModel: transactionVM,
                    categoryVM: categoryVM,
                    workspaceId: workspaceId,
                    transactionType: .income
                )
            }
            .sheet(isPresented: $showAddExpense) {
                TransactionFormView(
                    viewModel: transactionVM,
                    categoryVM: categoryVM,
                    workspaceId: workspaceId,
                    transactionType: .expense
                )
            }
            .sheet(item: $editingTransaction) { transaction in
                TransactionFormView(
                    viewModel: transactionVM,
                    categoryVM: categoryVM,
                    workspaceId: workspaceId,
                    editingTransaction: transaction
                )
            }
        }
    }
}

struct MonthlySummaryCard: View {
    let viewModel: TransactionViewModel
    private let now = Date()

    var body: some View {
        HStack(spacing: 12) {
            SummaryMiniCard(
                title: "Gelir",
                amount: viewModel.totalIncome(for: now),
                color: .green
            )
            SummaryMiniCard(
                title: "Gider",
                amount: viewModel.totalExpense(for: now),
                color: .red
            )
            SummaryMiniCard(
                title: "Net",
                amount: viewModel.netCashFlow(for: now),
                color: viewModel.netCashFlow(for: now) >= 0 ? .green : .red
            )
        }
    }
}

struct SummaryMiniCard: View {
    let title: String
    let amount: Double
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(amount.formatted())
                .font(.caption.bold())
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct TransactionRowView: View {
    let transaction: Transaction
    let category: Category?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: category?.icon ?? "circle.fill")
                .font(.title3)
                .foregroundStyle(Color(hex: category?.color ?? "#007AFF"))
                .frame(width: 36, height: 36)
                .background(Color(hex: category?.color ?? "#007AFF").opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(category?.name ?? String(localized: "Kategori Yok"))
                    .font(.subheadline.weight(.medium))
                if let desc = transaction.description, !desc.isEmpty {
                    Text(desc)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(transaction.type == .income ? "+\(transaction.amount.formatted())" : "-\(transaction.amount.formatted())")
                    .font(.subheadline.bold())
                    .foregroundStyle(transaction.type == .income ? .green : .red)
                if transaction.isRecurring {
                    Image(systemName: "repeat")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(category?.name ?? String(localized: "Kategori Yok")), \(transaction.type == .income ? String(localized: "gelir") : String(localized: "gider")), \(transaction.amount.formatted())")
    }
}

#Preview {
    TransactionListView()
}
