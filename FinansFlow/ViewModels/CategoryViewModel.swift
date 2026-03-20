import Foundation

@Observable
final class CategoryViewModel {
    var categories: [Category] = []
    var isLoading = false
    var errorMessage: String?

    private let service = SupabaseService.shared

    var incomeCategories: [Category] {
        categories.filter { category in category.type == .income && category.parentId == nil }
    }

    var expenseCategories: [Category] {
        categories.filter { category in category.type == .expense && category.parentId == nil }
    }

    func subcategories(of parentId: UUID) -> [Category] {
        categories.filter { category in category.parentId == parentId }
    }

    func loadCategories(workspaceId: UUID) async {
        isLoading = true
        defer { isLoading = false }

        do {
            categories = try await service.fetchAll(
                from: "categories",
                filters: [("workspace_id", workspaceId.uuidString)],
                orderBy: "name",
                ascending: true
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createCategory(
        workspaceId: UUID,
        name: String,
        type: CategoryType,
        parentId: UUID? = nil,
        color: String = "#007AFF",
        icon: String = "folder.fill",
        monthlyBudget: Double? = nil
    ) async throws {
        struct NewCategory: Encodable {
            let workspace_id: String
            let name: String
            let type: String
            let parent_id: String?
            let color: String
            let icon: String
            let monthly_budget: Double?
            let is_default: Bool
        }

        let new = NewCategory(
            workspace_id: workspaceId.uuidString,
            name: name,
            type: type.rawValue,
            parent_id: parentId?.uuidString,
            color: color,
            icon: icon,
            monthly_budget: monthlyBudget,
            is_default: false
        )

        let created: Category = try await service.insertReturning(into: "categories", value: new)
        categories.append(created)
    }

    func updateCategory(_ category: Category) async throws {
        struct UpdatePayload: Encodable {
            let name: String
            let color: String
            let icon: String
            let monthly_budget: Double?
            let parent_id: String?
        }

        try await service.update(
            table: "categories",
            id: category.id,
            value: UpdatePayload(
                name: category.name,
                color: category.color,
                icon: category.icon,
                monthly_budget: category.monthlyBudget,
                parent_id: category.parentId?.uuidString
            )
        )

        if let index = categories.firstIndex(where: { existingCategory in existingCategory.id == category.id }) {
            categories[index] = category
        }
    }

    func deleteCategory(_ category: Category) async throws {
        try await service.delete(from: "categories", id: category.id)
        categories.removeAll { existingCategory in existingCategory.id == category.id }
        // Also remove subcategories
        categories.removeAll { subcategory in subcategory.parentId == category.id }
    }
}
