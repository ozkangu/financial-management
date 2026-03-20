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
    @State private var selectedCategoryId: UUID?
    @State private var selectedVisibilityScope: VisibilityScope?
    @State private var useStartDate = false
    @State private var startDate = Date().startOfMonth
    @State private var useEndDate = false
    @State private var endDate = Date()

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

                if hasActiveFilters {
                    activeFiltersBar
                }

                // Transaction list
                let filtered = transactionVM.filteredTransactions(
                    type: selectedType,
                    categoryId: selectedCategoryId,
                    visibilityScope: selectedVisibilityScope,
                    searchText: searchText,
                    startDate: useStartDate ? startDate : nil,
                    endDate: useEndDate ? endDate : nil
                )

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
                            let txs1 = grouped[key1]!
                            let txs2 = grouped[key2]!
                            return (txs1.first?.date ?? Date()) > (txs2.first?.date ?? Date())
                        }

                        ForEach(sortedDates, id: \.self) { dateStr in
                            Section(dateStr) {
                                ForEach(grouped[dateStr] ?? []) { tx in
                                    TransactionRowView(
                                        transaction: tx,
                                        category: categoryVM.categories.first { $0.id == tx.categoryId }
                                    )
                                    .onTapGesture {
                                        HapticManager.selection()
                                        editingTransaction = tx
                                    }
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            Task {
                                                try? await transactionVM.deleteTransaction(tx)
                                                HapticManager.notification(.success)
                                            }
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
                        await transactionVM.loadTransactions(workspaceId: workspaceId, reset: true)
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
            .sheet(item: $editingTransaction) { tx in
                TransactionFormView(
                    viewModel: transactionVM,
                    categoryVM: categoryVM,
                    workspaceId: workspaceId,
                    editingTransaction: tx
                )
            }
            .sheet(isPresented: $showFilter) {
                TransactionFilterSheetView(
                    categoryVM: categoryVM,
                    selectedType: selectedType,
                    selectedCategoryId: $selectedCategoryId,
                    selectedVisibilityScope: $selectedVisibilityScope,
                    useStartDate: $useStartDate,
                    startDate: $startDate,
                    useEndDate: $useEndDate,
                    endDate: $endDate
                )
            }
            .onChange(of: selectedType) { _, newValue in
                normalizeCategoryFilter(selectedType: newValue)
            }
            .onChange(of: workspaceId) { _, _ in
                normalizeCategoryFilter(selectedType: selectedType, resetIfMissing: true)
            }
            .onChange(of: categoryVM.categories.map(\.id)) { _, _ in
                normalizeCategoryFilter(selectedType: selectedType, resetIfMissing: true)
            }
        }
    }

    private var hasActiveFilters: Bool {
        selectedCategoryId != nil || selectedVisibilityScope != nil || useStartDate || useEndDate
    }

    private var isFilterResultEmpty: Bool {
        TransactionFilterSupport.isFilterResultEmpty(
            hasTransactions: !transactionVM.transactions.isEmpty,
            hasActiveFilters: hasActiveFilters,
            searchText: searchText
        )
    }

    private var activeFiltersBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if let selectedCategoryId,
                   let category = categoryVM.categories.first(where: { $0.id == selectedCategoryId }) {
                    FilterChip(label: category.name) {
                        self.selectedCategoryId = nil
                    }
                }

                if let selectedVisibilityScope {
                    FilterChip(
                        label: selectedVisibilityScope == .personal ? "Kişisel" : "Ortak"
                    ) {
                        self.selectedVisibilityScope = nil
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
        selectedCategoryId = nil
        selectedVisibilityScope = nil
        useStartDate = false
        useEndDate = false
        searchText = ""
    }

    private func normalizeCategoryFilter(
        selectedType: TransactionType?,
        resetIfMissing: Bool = false
    ) {
        selectedCategoryId = TransactionFilterSupport.normalizedCategorySelection(
            selectedCategoryId: selectedCategoryId,
            categories: categoryVM.categories,
            selectedType: selectedType,
            resetIfMissing: resetIfMissing
        )
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

struct TransactionFilterSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var categoryVM: CategoryViewModel
    let selectedType: TransactionType?

    @Binding var selectedCategoryId: UUID?
    @Binding var selectedVisibilityScope: VisibilityScope?
    @Binding var useStartDate: Bool
    @Binding var startDate: Date
    @Binding var useEndDate: Bool
    @Binding var endDate: Date

    var body: some View {
        NavigationStack {
            Form {
                Section("Kategori") {
                    Picker("Kategori", selection: $selectedCategoryId) {
                        Text("Tümü").tag(UUID?.none)
                        ForEach(
                            TransactionFilterSupport.availableCategories(
                                categories: categoryVM.categories,
                                selectedType: selectedType
                            )
                        ) { category in
                            Text(category.name).tag(UUID?.some(category.id))
                        }
                    }
                }

                Section("Kapsam") {
                    Picker("Görünürlük", selection: $selectedVisibilityScope) {
                        Text("Tümü").tag(VisibilityScope?.none)
                        Text("Kişisel").tag(VisibilityScope?.some(.personal))
                        Text("Ortak").tag(VisibilityScope?.some(.shared))
                    }
                    .pickerStyle(.segmented)
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
                        selectedCategoryId = nil
                        selectedVisibilityScope = nil
                        useStartDate = false
                        useEndDate = false
                    }
                }
            }
        }
    }
}

enum TransactionFilterSupport {
    static func availableCategories(
        categories: [Category],
        selectedType: TransactionType?
    ) -> [Category] {
        guard let selectedType else { return categories }
        return categories.filter { $0.type.rawValue == selectedType.rawValue }
    }

    static func normalizedCategorySelection(
        selectedCategoryId: UUID?,
        categories: [Category],
        selectedType: TransactionType?,
        resetIfMissing: Bool
    ) -> UUID? {
        guard let selectedCategoryId else { return nil }

        let availableCategoryIds = Set(
            availableCategories(
                categories: categories,
                selectedType: selectedType
            ).map(\.id)
        )

        if resetIfMissing || !availableCategoryIds.contains(selectedCategoryId) {
            return nil
        }

        return selectedCategoryId
    }

    static func isFilterResultEmpty(
        hasTransactions: Bool,
        hasActiveFilters: Bool,
        searchText: String
    ) -> Bool {
        hasTransactions && (hasActiveFilters || !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
}
