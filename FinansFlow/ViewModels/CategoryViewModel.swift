import Foundation
import SwiftData

@Observable
final class CategoryViewModel {
    var categories: [Category] = []
    var isLoading = false
    var errorMessage: String?

    var incomeCategories: [Category] {
        categories.filter { $0.type == .income && $0.parent == nil }
    }

    var expenseCategories: [Category] {
        categories.filter { $0.type == .expense && $0.parent == nil }
    }

    func loadCategories(context: ModelContext) {
        isLoading = true
        defer { isLoading = false }

        do {
            let descriptor = FetchDescriptor<Category>(sortBy: [SortDescriptor(\.name)])
            categories = try context.fetch(descriptor)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createCategory(
        context: ModelContext,
        name: String,
        type: CategoryType,
        parent: Category? = nil,
        color: String = "#007AFF",
        icon: String = "folder.fill",
        monthlyBudget: Double? = nil
    ) {
        let category = Category(
            name: name,
            type: type,
            parent: parent,
            color: color,
            icon: icon,
            monthlyBudget: monthlyBudget
        )
        context.insert(category)
        try? context.save()
        categories.append(category)
    }

    func updateCategory(_ category: Category, context: ModelContext) {
        try? context.save()
        if let idx = categories.firstIndex(where: { $0.id == category.id }) {
            categories[idx] = category
        }
    }

    func deleteCategory(_ category: Category, context: ModelContext) {
        let subcats = category.subcategories
        for sub in subcats {
            context.delete(sub)
        }
        context.delete(category)
        try? context.save()
        categories.removeAll { $0.id == category.id }
        for sub in subcats {
            categories.removeAll { $0.id == sub.id }
        }
    }
}
