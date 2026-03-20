import Foundation

@Observable
final class WorkspaceViewModel {
    var workspaces: [Workspace] = []
    var activeWorkspace: Workspace?
    var members: [WorkspaceMember] = []
    var isLoading = false
    var errorMessage: String?

    private let service = SupabaseService.shared

    // MARK: - Auto-create personal workspace on signup

    func ensurePersonalWorkspace(userId: UUID, userName: String) async {
        do {
            let existing: [Workspace] = try await service.fetchAll(
                from: "workspaces",
                filters: [("owner_id", userId.uuidString)]
            )
            if existing.isEmpty {
                try await createWorkspace(name: "\(userName) Kişisel", userId: userId)
            }
            await loadWorkspaces(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - CRUD

    func loadWorkspaces(userId: UUID) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let allMembers: [WorkspaceMember] = try await service.fetchAll(
                from: "workspace_members",
                filters: [("user_id", userId.uuidString), ("status", "active")]
            )
            let workspaceIds = allMembers.map(\.workspaceId)
            var loaded: [Workspace] = []
            for wsId in workspaceIds {
                let ws: Workspace = try await service.fetchOne(from: "workspaces", id: wsId)
                loaded.append(ws)
            }
            workspaces = loaded
            if activeWorkspace == nil {
                activeWorkspace = workspaces.first
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createWorkspace(name: String, userId: UUID) async throws {
        struct NewWorkspace: Encodable {
            let name: String
            let owner_id: String
        }
        let ws: Workspace = try await service.insertReturning(
            into: "workspaces",
            value: NewWorkspace(name: name, owner_id: userId.uuidString)
        )

        struct NewMember: Encodable {
            let workspace_id: String
            let user_id: String
            let role: String
            let status: String
            let accepted_at: String
        }
        let now = ISO8601DateFormatter().string(from: Date())
        try await service.insert(
            into: "workspace_members",
            value: NewMember(
                workspace_id: ws.id.uuidString,
                user_id: userId.uuidString,
                role: "owner",
                status: "active",
                accepted_at: now
            )
        )

        // Seed default categories
        try await seedDefaultCategories(workspaceId: ws.id)

        workspaces.append(ws)
        if activeWorkspace == nil {
            activeWorkspace = ws
        }
    }

    func updateWorkspace(_ workspace: Workspace) async throws {
        struct UpdatePayload: Encodable {
            let name: String
        }
        try await service.update(
            table: "workspaces",
            id: workspace.id,
            value: UpdatePayload(name: workspace.name)
        )
        if let index = workspaces.firstIndex(where: { existingWorkspace in existingWorkspace.id == workspace.id }) {
            workspaces[index] = workspace
        }
    }

    func deleteWorkspace(_ workspace: Workspace) async throws {
        try await service.delete(from: "workspaces", id: workspace.id)
        workspaces.removeAll { existingWorkspace in existingWorkspace.id == workspace.id }
        if activeWorkspace?.id == workspace.id {
            activeWorkspace = workspaces.first
        }
    }

    // MARK: - Members

    func loadMembers() async {
        guard let activeWorkspaceData = activeWorkspace else { return }
        do {
            members = try await service.fetchAll(
                from: "workspace_members",
                filters: [("workspace_id", activeWorkspaceData.id.uuidString)]
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func inviteMember(email: String, userId: UUID, workspaceId: UUID) async throws {
        struct InvitePayload: Encodable {
            let workspace_id: String
            let user_id: String
            let role: String
            let status: String
        }
        try await service.insert(
            into: "workspace_members",
            value: InvitePayload(
                workspace_id: workspaceId.uuidString,
                user_id: userId.uuidString,
                role: "member",
                status: "pending"
            )
        )
        await loadMembers()
    }

    func acceptInvitation(memberId: UUID) async throws {
        struct AcceptPayload: Encodable {
            let status: String
            let accepted_at: String
        }
        let now = ISO8601DateFormatter().string(from: Date())
        try await service.update(
            table: "workspace_members",
            id: memberId,
            value: AcceptPayload(status: "active", accepted_at: now)
        )
    }

    func removeMember(memberId: UUID) async throws {
        try await service.delete(from: "workspace_members", id: memberId)
        members.removeAll { existingMember in existingMember.id == memberId }
    }

    // MARK: - Category Seeding

    private func seedDefaultCategories(workspaceId: UUID) async throws {
        // Call the Supabase function to seed categories
        try await SupabaseConfig.client.rpc("seed_default_categories", params: ["ws_id": workspaceId.uuidString]).execute()
    }
}
