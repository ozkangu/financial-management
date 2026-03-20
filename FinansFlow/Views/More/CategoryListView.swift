import SwiftUI

struct CategoryListView: View {
    @Bindable var viewModel: CategoryViewModel
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
                    CategoryRowView(category: category)
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
                        CategoryRowView(category: sub, isSubcategory: true)
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
    let category: Category
    var isSubcategory: Bool = false

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
                if let budget = category.monthlyBudget, budget > 0 {
                    Text("Bütçe: \(budget.formatted())")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
    }
}
