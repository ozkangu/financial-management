import SwiftUI
import SwiftData

struct TransactionListView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var transactionVM: TransactionViewModel
    @Bindable var categoryVM: CategoryViewModel

    @State private var selectedType: TransactionType? = nil
    @State private var searchText = ""
    @State private var showAddIncome = false
    @State private var showAddExpense = false
    @State private var editingTransaction: Transaction?
    @State private var showFilter = false
    @State private var selectedCategory: Category?
    @State private var useStartDate = false
    @State private var startDate = Date().startOfMonth
    @State private var useEndDate = false
    @State private var endDate = Date()

    init(
        transactionVM: TransactionViewModel = TransactionViewModel(),
        categoryVM: CategoryViewModel = CategoryViewModel()
    ) {
        self.transactionVM = transactionVM
        self.categoryVM = categoryVM
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                MonthlySummaryCard(viewModel: transactionVM)
                    .padding()

                Picker("Tür", selection: $selectedType) {
                    Text("Tümü").tag(TransactionType?.none)
                    Text("Gelir").tag(TransactionType?.some(.income))
                    Text("Gider").tag(TransactionType?.some(.expense))
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                if hasActiveFilters {
                    activeFiltersBar
                }

                let filtered = transactionVM.filteredTransactions(
                    type: selectedType,
                    category: selectedCategory,
                    searchText: searchText
                ).filter { transaction in
                    if useStartDate, transaction.date < startDate { return false }
                    if useEndDate, transaction.date > endDate { return false }
                    return true
                }

                if filtered.isEmpty && !transactionVM.isLoading {
                    if isFilterResultEmpty {
                        EmptyStateView(
                            icon: "line.3.horizontal.decrease.circle",
                            title: "Sonuc Bulunamadi",
                            description: "Secili filtreler veya arama sonucu eslesen islem yok",
                            actionTitle: searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? "Filtreleri Temizle"
                                : "Arama ve Filtreleri Temizle"
                        ) {
                            clearFilters()
                        }
                    } else {
                        EmptyStateView(
                            icon: "tray.fill",
                            title: "Henüz İşlem Yok",
                            description: "İlk gelir veya gider kaydınızı oluşturun",
                            actionTitle: "İşlem Ekle"
                        ) {
                            showAddExpense = true
                        }
                    }
                } else {
                    List {
                        let grouped = Dictionary(grouping: filtered) { $0.date.displayString }
                        let sortedDates = grouped.keys.sorted { key1, key2 in
                            let txs1 = grouped[key1] ?? []
                            let txs2 = grouped[key2] ?? []
                            return (txs1.first?.date ?? Date()) > (txs2.first?.date ?? Date())
                        }

                        ForEach(sortedDates, id: \.self) { dateStr in
                            Section(dateStr) {
                                ForEach(grouped[dateStr] ?? []) { tx in
                                    TransactionRowView(
                                        transaction: tx,
                                        category: tx.category
                                    )
                                    .onTapGesture {
                                        HapticManager.selection()
                                        editingTransaction = tx
                                    }
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            transactionVM.deleteTransaction(tx, context: modelContext)
                                            HapticManager.notification(.success)
                                        } label: {
                                            Label("Sil", systemImage: "trash")
                                        }

                                        Button {
                                            editingTransaction = tx
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
                        transactionVM.loadTransactions(context: modelContext)
                    }
                }
            }
            .navigationTitle("İşlemler")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showFilter = true
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }

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
                    transactionType: .income
                )
            }
            .sheet(isPresented: $showAddExpense) {
                TransactionFormView(
                    viewModel: transactionVM,
                    categoryVM: categoryVM,
                    transactionType: .expense
                )
            }
            .sheet(item: $editingTransaction) { transaction in
                TransactionFormView(
                    viewModel: transactionVM,
                    categoryVM: categoryVM,
                    editingTransaction: transaction
                )
            }
            .sheet(isPresented: $showFilter) {
                TransactionFilterSheetView(
                    categoryVM: categoryVM,
                    selectedType: selectedType,
                    selectedCategory: $selectedCategory,
                    useStartDate: $useStartDate,
                    startDate: $startDate,
                    useEndDate: $useEndDate,
                    endDate: $endDate
                )
            }
        }
    }

    private var hasActiveFilters: Bool {
        selectedCategory != nil ||
        useStartDate ||
        useEndDate ||
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var isFilterResultEmpty: Bool {
        !transactionVM.transactions.isEmpty && hasActiveFilters
    }

    private var activeFiltersBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if let selectedCategory {
                    FilterChip(label: selectedCategory.name) {
                        self.selectedCategory = nil
                    }
                }

                if useStartDate {
                    FilterChip(label: "Başlangıç: \(startDate.displayString)") {
                        useStartDate = false
                    }
                }

                if useEndDate {
                    FilterChip(label: "Bitiş: \(endDate.displayString)") {
                        useEndDate = false
                    }
                }

                Button("Temizle") {
                    clearFilters()
                }
                .font(.caption.weight(.semibold))
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }

    private func clearFilters() {
        selectedCategory = nil
        useStartDate = false
        useEndDate = false
        searchText = ""
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
                if let desc = transaction.descriptionText, !desc.isEmpty {
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

struct TransactionFilterSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var categoryVM: CategoryViewModel
    let selectedType: TransactionType?

    @Binding var selectedCategory: Category?
    @Binding var useStartDate: Bool
    @Binding var startDate: Date
    @Binding var useEndDate: Bool
    @Binding var endDate: Date

    var body: some View {
        NavigationStack {
            Form {
                Section("Kategori") {
                    Picker("Kategori", selection: $selectedCategory) {
                        Text("Tümü").tag(Category?.none)
                        ForEach(availableCategories) { category in
                            Text(category.name).tag(Category?.some(category))
                        }
                    }
                }

                Section("Tarih Aralığı") {
                    Toggle("Başlangıç Tarihi", isOn: $useStartDate)
                    if useStartDate {
                        DatePicker("Başlangıç", selection: $startDate, displayedComponents: .date)
                    }

                    Toggle("Bitiş Tarihi", isOn: $useEndDate)
                    if useEndDate {
                        DatePicker("Bitiş", selection: $endDate, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("Filtreler")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Sıfırla") {
                        selectedCategory = nil
                        useStartDate = false
                        useEndDate = false
                    }
                }
            }
        }
    }

    private var availableCategories: [Category] {
        guard let selectedType else { return categoryVM.categories }
        return categoryVM.categories.filter { $0.type.rawValue == selectedType.rawValue }
    }
}

struct FilterChip: View {
    let label: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.caption)
            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(.systemGray6))
        .clipShape(Capsule())
    }
}

#Preview {
    TransactionListView()
        .modelContainer(for: [Category.self, Transaction.self], inMemory: true)
}
