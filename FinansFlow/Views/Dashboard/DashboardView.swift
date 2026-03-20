import SwiftUI
import Charts

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var transactionVM: TransactionViewModel
    @Bindable var categoryVM: CategoryViewModel

    @State private var showAddIncome = false
    @State private var showAddExpense = false

    init(transactionVM: TransactionViewModel = TransactionViewModel(),
         categoryVM: CategoryViewModel = CategoryViewModel()) {
        self.transactionVM = transactionVM
        self.categoryVM = categoryVM
    }

    private let now = Date()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    netWorthCard
                    monthlySummaryCards
                    cashFlowChart
                    expenseCategoryChart

                    HStack(spacing: 12) {
                        passiveIncomeMiniCard
                        upcomingPaymentsCard
                    }
                    .padding(.horizontal)

                    recentTransactionsSection
                }
                .padding(.vertical)
            }
            .navigationTitle("Dashboard")
            .overlay(alignment: .bottomTrailing) {
                floatingActionButton
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
        }
    }

    // MARK: - Net Worth Card

    private var netWorthCard: some View {
        VStack(spacing: 8) {
            Text("NET VARLIK")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text("--")
                .font(.title.bold())
            Text("Hesaplama için varlık/borç ekleyin")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        .padding(.horizontal)
    }

    // MARK: - Monthly Summary Cards

    private var monthlySummaryCards: some View {
        HStack(spacing: 12) {
            DashboardSummaryCard(
                title: "Gelir",
                amount: transactionVM.totalIncome(for: now),
                color: .green,
                icon: "arrow.down.circle.fill"
            )
            DashboardSummaryCard(
                title: "Gider",
                amount: transactionVM.totalExpense(for: now),
                color: .red,
                icon: "arrow.up.circle.fill"
            )
            DashboardSummaryCard(
                title: "Net",
                amount: transactionVM.netCashFlow(for: now),
                color: transactionVM.netCashFlow(for: now) >= 0 ? .green : .red,
                icon: "equal.circle.fill"
            )
        }
        .padding(.horizontal)
    }

    // MARK: - Cash Flow Chart (6 months)

    private var cashFlowChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("NAKİT AKIŞI")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            let data = last6MonthsData
            if data.isEmpty {
                Text("Henüz veri yok")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .frame(height: 180)
                    .frame(maxWidth: .infinity)
            } else {
                Chart(data) { item in
                    BarMark(
                        x: .value("Ay", item.month),
                        y: .value("Tutar", item.amount)
                    )
                    .foregroundStyle(by: .value("Tür", item.type))
                }
                .chartForegroundStyleScale([
                    String(localized: "Gelir"): Color.green,
                    String(localized: "Gider"): Color.red
                ])
                .frame(height: 180)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        .padding(.horizontal)
    }

    private var last6MonthsData: [MonthlyChartData] {
        var data: [MonthlyChartData] = []
        for i in (0..<6).reversed() {
            let month = now.monthsAgo(i)
            let income = transactionVM.totalIncome(for: month)
            let expense = transactionVM.totalExpense(for: month)
            let label = month.monthYearString
            if income > 0 || expense > 0 {
                data.append(MonthlyChartData(month: label, type: String(localized: "Gelir"), amount: income))
                data.append(MonthlyChartData(month: label, type: String(localized: "Gider"), amount: expense))
            }
        }
        return data
    }

    // MARK: - Expense Category Donut Chart

    private var expenseCategoryChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("GİDER DAĞILIMI")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            let categoryData = expenseByCategoryData
            if categoryData.isEmpty {
                Text("Bu ay gider kaydı yok")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .frame(height: 180)
                    .frame(maxWidth: .infinity)
            } else {
                Chart(categoryData) { item in
                    SectorMark(
                        angle: .value("Tutar", item.amount),
                        innerRadius: .ratio(0.6),
                        angularInset: 1
                    )
                    .foregroundStyle(Color(hex: item.color))
                    .annotation(position: .overlay) {
                        if item.percentage > 10 {
                            Text("\(Int(item.percentage))%")
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                        }
                    }
                }
                .frame(height: 180)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 4) {
                    ForEach(categoryData.prefix(6)) { item in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color(hex: item.color))
                                .frame(width: 8, height: 8)
                            Text(item.name)
                                .font(.caption2)
                                .lineLimit(1)
                            Spacer()
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

    private var expenseByCategoryData: [CategoryChartData] {
        let monthExpenses = transactionVM.transactions.filter {
            $0.type == .expense && $0.date >= now.startOfMonth && $0.date <= now.endOfMonth
        }
        let grouped = Dictionary(grouping: monthExpenses) { $0.category?.id }
        let total = monthExpenses.reduce(0.0) { $0 + $1.amount }
        guard total > 0 else { return [] }

        return grouped.compactMap { (catId, txs) -> CategoryChartData? in
            let amount = txs.reduce(0.0) { $0 + $1.amount }
            let cat = txs.first?.category
            return CategoryChartData(
                id: catId ?? UUID(),
                name: cat?.name ?? String(localized: "Diğer"),
                amount: amount,
                color: cat?.color ?? "#999999",
                percentage: (amount / total) * 100
            )
        }
        .sorted { $0.amount > $1.amount }
    }

    // MARK: - Passive Income Mini Card

    private var passiveIncomeMiniCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PASİF GELİR")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text("--/ay")
                .font(.headline)
            Text("Oran: --%")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }

    // MARK: - Upcoming Payments

    private var upcomingPaymentsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("YAKLAŞAN")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            let recurring = transactionVM.transactions.filter { $0.isRecurring }.prefix(3)
            if recurring.isEmpty {
                Text("Yok")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            } else {
                ForEach(Array(recurring)) { tx in
                    HStack {
                        Circle()
                            .fill(tx.type == .income ? Color.green : Color.red)
                            .frame(width: 6, height: 6)
                        Text(tx.descriptionText ?? String(localized: "İşlem"))
                            .font(.caption)
                            .lineLimit(1)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }

    // MARK: - Recent Transactions

    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("SON İŞLEMLER")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Tümünü Gör")
                    .font(.caption)
                    .foregroundStyle(Color.accentColor)
            }

            let recent = Array(transactionVM.transactions.prefix(5))
            if recent.isEmpty {
                Text("Henüz işlem yok")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .padding(.vertical, 8)
            } else {
                ForEach(recent) { tx in
                    TransactionRowView(
                        transaction: tx,
                        category: tx.category
                    )
                    if tx.id != recent.last?.id {
                        Divider()
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

    // MARK: - FAB

    private var floatingActionButton: some View {
        Menu {
            Button {
                HapticManager.impact(.medium)
                showAddIncome = true
            } label: {
                Label("Gelir Ekle", systemImage: "plus.circle.fill")
            }
            Button {
                HapticManager.impact(.medium)
                showAddExpense = true
            } label: {
                Label("Gider Ekle", systemImage: "minus.circle.fill")
            }
        } label: {
            Image(systemName: "plus")
                .font(.title2.bold())
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Color.accentColor)
                .clipShape(Circle())
                .shadow(color: .accentColor.opacity(0.3), radius: 8, y: 4)
        }
        .accessibilityLabel(String(localized: "Yeni işlem ekle"))
        .padding(.trailing, 20)
        .padding(.bottom, 20)
    }
}

// MARK: - Supporting Views

struct DashboardSummaryCard: View {
    let title: String
    let amount: Double
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(amount.formatted())
                .font(.subheadline.bold())
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(amount.formatted())")
    }
}

// MARK: - Chart Data Models

struct MonthlyChartData: Identifiable {
    let id = UUID()
    let month: String
    let type: String
    let amount: Double
}

struct CategoryChartData: Identifiable {
    let id: UUID
    let name: String
    let amount: Double
    let color: String
    let percentage: Double
}

#Preview {
    DashboardView()
        .modelContainer(for: [Category.self, Transaction.self], inMemory: true)
}
