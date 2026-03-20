import Foundation
import Supabase

actor SupabaseService {
    static let shared = SupabaseService()

    private var client: SupabaseClient {
        SupabaseConfig.client
    }

    // MARK: - Generic CRUD

    func fetchAll<T: Decodable & Sendable>(
        from table: String,
        filters: [(column: String, value: String)] = [],
        orderBy: String? = nil,
        ascending: Bool = false,
        limit: Int? = nil
    ) async throws -> [T] {
        var query = client.from(table).select()

        for filter in filters {
            query = query.eq(filter.column, value: filter.value)
        }

        if let orderBy, let limit {
            return try await query
                .order(orderBy, ascending: ascending)
                .limit(limit)
                .execute()
                .value
        } else if let orderBy {
            return try await query
                .order(orderBy, ascending: ascending)
                .execute()
                .value
        } else if let limit {
            return try await query
                .limit(limit)
                .execute()
                .value
        } else {
            return try await query
                .execute()
                .value
        }
    }

    func fetchTransactionsPage(
        query: TransactionFeedQuery,
        offset: Int,
        limit: Int
    ) async throws -> [Transaction] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        var request = client.from("transactions")
            .select()
            .eq("workspace_id", value: query.workspaceId.uuidString)

        if let type = query.type {
            request = request.eq("type", value: type.rawValue)
        }

        if let categoryId = query.categoryId {
            request = request.eq("category_id", value: categoryId.uuidString)
        }

        if let visibilityScope = query.visibilityScope {
            request = request.eq("visibility_scope", value: visibilityScope.rawValue)
        }

        if let startDate = query.startDate {
            request = request.gte("date", value: dateFormatter.string(from: startDate))
        }

        if let endDate = query.endDate {
            request = request.lte("date", value: dateFormatter.string(from: endDate))
        }

        if !query.searchText.isEmpty {
            request = request.ilike("description", pattern: "%\(query.searchText)%")
        }

        return try await request
            .order("date", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute()
            .value
    }

    func fetchOne<T: Decodable & Sendable>(
        from table: String,
        id: UUID
    ) async throws -> T {
        try await client.from(table)
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value
    }

    func insert<T: Encodable & Sendable>(
        into table: String,
        value: T
    ) async throws {
        try await client.from(table)
            .insert(value)
            .execute()
    }

    func insertReturning<T: Encodable & Sendable, R: Decodable & Sendable>(
        into table: String,
        value: T
    ) async throws -> R {
        try await client.from(table)
            .insert(value)
            .select()
            .single()
            .execute()
            .value
    }

    func update<T: Encodable & Sendable>(
        table: String,
        id: UUID,
        value: T
    ) async throws {
        try await client.from(table)
            .update(value)
            .eq("id", value: id.uuidString)
            .execute()
    }

    func delete(
        from table: String,
        id: UUID
    ) async throws {
        try await client.from(table)
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Auth Helpers

    var currentUserId: UUID? {
        get async {
            try? await client.auth.session.user.id
        }
    }
}
