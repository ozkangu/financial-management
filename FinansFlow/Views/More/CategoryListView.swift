import SwiftUI

struct CategoryListView: View {
    @Bindable var viewModel: CategoryViewModel
    @Bindable var transactionVM: TransactionViewModel
    let workspaceId: UUID

    @State private var selectedType: CategoryType = .expense
    @State private var showAddSheet = false
    @State private var editingCategory: Category?

    var body: some View {
        List {
            Picker("Tür", selection: $selectedType) {
                Text("Gider").tag(CategoryType.expense)
                Text("Gelir").tag(CategoryType.income)
            }
            .pickerStyle(.segmented)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
            .padding(.horizontal)

            let parentCategories = selectedType == .expense
                ? viewModel.expenseCategories
                : viewModel.incomeCategories

            ForEach(parentCategories) { category in
                Section {
                    CategoryRowView(
                        category: category,
                        allCategories: viewModel.categories
                    )
                        .onTapGesture { editingCategory = category }
                        .swipeActions(edge: .trailing) {
                            if !category.isDefault {
                                Button(role: .destructive) {
                                    Task { try? await viewModel.deleteCategory(category) }
                                } label: {
                                    Label("Sil", systemImage: "trash")
                                }
                            }
                        }

                    let subs = viewModel.subcategories(of: category.id)
                    ForEach(subs) { sub in
                        CategoryRowView(
                            category: sub,
                            allCategories: viewModel.categories,
                            isSubcategory: true
                        )
                            .onTapGesture { editingCategory = sub }
                            .swipeActions(edge: .trailing) {
                                if !sub.isDefault {
                                    Button(role: .destructive) {
                                        Task { try? await viewModel.deleteCategory(sub) }
                                    } label: {
                                        Label("Sil", systemImage: "trash")
                                    }
                                }
                            }
                    }
                }
            }
        }
        .navigationTitle("Kategoriler")
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
            CategoryFormView(
                viewModel: viewModel,
                workspaceId: workspaceId,
                categoryType: selectedType
            )
        }
        .sheet(item: $editingCategory) { category in
            CategoryFormView(
                viewModel: viewModel,
                workspaceId: workspaceId,
                editingCategory: category
            )
        }
        .task {
            await viewModel.loadCategories(workspaceId: workspaceId)
        }
    }
}

struct CategoryRowView: View {
    @Environment(TransactionViewModel.self) private var transactionVM
    let category: Category
    let allCategories: [Category]
    var isSubcategory: Bool = false

    private var budgetSummary: DashboardCategoryBudgetSummary? {
        guard category.type == .expense, (category.monthlyBudget ?? 0) > 0 else { return nil }
        return DashboardMetrics.categoryBudgetSummaries(
            categories: allCategories,
            transactions: transactionVM.transactions,
            referenceDate: Date()
        ).first(where: { $0.id == category.id })
    }

    var body: some View {
        HStack(spacing: 12) {
            if isSubcategory {
                Spacer().frame(width: 20)
            }
            Image(systemName: category.icon)
                .font(.title3)
                .foregroundStyle(Color(hex: category.color))
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(category.name)
                    .font(isSubcategory ? .subheadline : .headline)
                if let budgetSummary {
                    Text("Bütçe: \(budgetSummary.spent.formatted()) / \(budgetSummary.budget.formatted())")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ProgressView(value: min(budgetSummary.utilization, 1.0))
                        .tint(categoryBudgetColor(for: budgetSummary.status))
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
    }

    private func categoryBudgetColor(for status: DashboardBudgetStatus) -> Color {
        switch status {
        case .onTrack:
            return .green
        case .warning:
            return .orange
        case .exceeded:
            return .red
        }
    }
}
