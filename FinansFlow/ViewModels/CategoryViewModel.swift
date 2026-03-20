import Foundation

@Observable
final class CategoryViewModel {
    var categories: [Category] = []
    var isLoading = false
    var errorMessage: String?

    private let service = SupabaseService.shared
    private var latestWorkspaceId: UUID?

    var incomeCategories: [Category] {
        categories.filter { $0.type == .income && $0.parentId == nil }
    }

    var expenseCategories: [Category] {
        categories.filter { $0.type == .expense && $0.parentId == nil }
    }

    func subcategories(of parentId: UUID) -> [Category] {
        categories.filter { $0.parentId == parentId }
    }

    func loadCategories(workspaceId: UUID) async {
        latestWorkspaceId = workspaceId
        isLoading = true
        defer {
            if latestWorkspaceId == workspaceId {
                isLoading = false
            }
        }

        do {
            let fetched: [Category] = try await service.fetchAll(
                from: "categories",
                filters: [("workspace_id", workspaceId.uuidString)],
                orderBy: "name",
                ascending: true
            )
            guard latestWorkspaceId == workspaceId else { return }
            categories = fetched
        } catch {
            guard latestWorkspaceId == workspaceId else { return }
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

        if let idx = categories.firstIndex(where: { $0.id == category.id }) {
            categories[idx] = category
        }
    }

    func deleteCategory(_ category: Category) async throws {
        try await service.delete(from: "categories", id: category.id)
        categories.removeAll { $0.id == category.id }
        // Also remove subcategories
        categories.removeAll { $0.parentId == category.id }
    }
}
