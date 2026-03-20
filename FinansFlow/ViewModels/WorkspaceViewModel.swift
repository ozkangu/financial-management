import Foundation

@Observable
final class WorkspaceViewModel {
    var workspaces: [Workspace] = []
    var activeWorkspace: Workspace?
    var members: [WorkspaceMember] = []
    var pendingInvitations: [WorkspaceMember] = []
    var memberProfiles: [UUID: AppUser] = [:]
    var invitationWorkspaces: [UUID: Workspace] = [:]
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
            let activeMemberships: [WorkspaceMember] = try await service.fetchAll(
                from: "workspace_members",
                filters: [("user_id", userId.uuidString), ("status", "active")]
            )
            let pendingMemberships: [WorkspaceMember] = try await service.fetchAll(
                from: "workspace_members",
                filters: [("user_id", userId.uuidString), ("status", "pending")]
            )

            workspaces = try await fetchWorkspaces(ids: activeMemberships.map(\.workspaceId))
            pendingInvitations = pendingMemberships
            invitationWorkspaces = try await fetchWorkspaceLookup(ids: pendingMemberships.map(\.workspaceId))
            activeWorkspace = resolvedActiveWorkspace(
                current: activeWorkspace,
                available: workspaces
            )
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
        if let idx = workspaces.firstIndex(where: { $0.id == workspace.id }) {
            workspaces[idx] = workspace
        }
    }

    func deleteWorkspace(_ workspace: Workspace) async throws {
        try await service.delete(from: "workspaces", id: workspace.id)
        workspaces.removeAll { $0.id == workspace.id }
        if activeWorkspace?.id == workspace.id {
            activeWorkspace = workspaces.first
        }
    }

    // MARK: - Members

    func loadMembers() async {
        guard let ws = activeWorkspace else { return }
        do {
            members = try await service.fetchAll(
                from: "workspace_members",
                filters: [("workspace_id", ws.id.uuidString)]
            )
            memberProfiles = try await fetchUserLookup(userIds: members.map(\.userId))
            members = sortedMembers(members)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func inviteMember(email: String, workspaceId: UUID, currentUserId: UUID) async throws {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalizedEmail.isEmpty else {
            throw WorkspaceCollaborationError.invalidEmail
        }

        let matchedUsers: [AppUser] = try await service.fetchAll(
            from: "users",
            filters: [("email", normalizedEmail)]
        )
        guard let invitedUser = matchedUsers.first else {
            throw WorkspaceCollaborationError.userNotFound
        }
        guard invitedUser.id != currentUserId else {
            throw WorkspaceCollaborationError.cannotInviteYourself
        }

        let existingMembers: [WorkspaceMember] = try await service.fetchAll(
            from: "workspace_members",
            filters: [("workspace_id", workspaceId.uuidString), ("user_id", invitedUser.id.uuidString)]
        )
        guard existingMembers.isEmpty else {
            throw WorkspaceCollaborationError.alreadyMemberOrInvited
        }

        struct InvitePayload: Encodable {
            let workspace_id: String
            let user_id: String
            let role: String
            let status: String
            let invited_at: String
        }
        let now = ISO8601DateFormatter().string(from: Date())
        try await service.insert(
            into: "workspace_members",
            value: InvitePayload(
                workspace_id: workspaceId.uuidString,
                user_id: invitedUser.id.uuidString,
                role: "member",
                status: "pending",
                invited_at: now
            )
        )
        await loadMembers()
    }

    func acceptInvitation(memberId: UUID, userId: UUID) async throws {
        let acceptedWorkspaceId = pendingInvitations.first(where: { $0.id == memberId })?.workspaceId
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
        await loadWorkspaces(userId: userId)
        if let acceptedWorkspaceId {
            activeWorkspace = workspaces.first(where: { $0.id == acceptedWorkspaceId })
        }
    }

    func removeMember(memberId: UUID) async throws {
        try await service.delete(from: "workspace_members", id: memberId)
        members.removeAll { $0.id == memberId }
    }

    // MARK: - Category Seeding

    private func seedDefaultCategories(workspaceId: UUID) async throws {
        // Call the Supabase function to seed categories
        try await SupabaseConfig.client.rpc("seed_default_categories", params: ["ws_id": workspaceId.uuidString]).execute()
    }

    private func fetchWorkspaces(ids: [UUID]) async throws -> [Workspace] {
        try await ids.asyncCompactMap { workspaceId in
            try await service.fetchOne(from: "workspaces", id: workspaceId) as Workspace
        }
    }

    private func fetchWorkspaceLookup(ids: [UUID]) async throws -> [UUID: Workspace] {
        let workspaces = try await fetchWorkspaces(ids: Array(Set(ids)))
        return Dictionary(uniqueKeysWithValues: workspaces.map { ($0.id, $0) })
    }

    private func fetchUserLookup(userIds: [UUID]) async throws -> [UUID: AppUser] {
        let users = try await Array(Set(userIds)).asyncCompactMap { userId in
            try await service.fetchOne(from: "users", id: userId) as AppUser
        }
        return Dictionary(uniqueKeysWithValues: users.map { ($0.id, $0) })
    }

    func displayName(for member: WorkspaceMember) -> String {
        if let profile = memberProfiles[member.userId] {
            if let name = profile.name, !name.isEmpty {
                return name
            }
            return profile.email
        }

        return member.userId.uuidString
    }

    func subtitle(for member: WorkspaceMember) -> String {
        if let profile = memberProfiles[member.userId] {
            return profile.email
        }

        return member.role.rawValue.capitalized
    }

    func workspaceName(for invitation: WorkspaceMember) -> String {
        invitationWorkspaces[invitation.workspaceId]?.name ?? "Workspace"
    }

    func resolvedActiveWorkspace(current: Workspace?, available: [Workspace]) -> Workspace? {
        guard let current else {
            return available.first
        }

        return available.first(where: { $0.id == current.id }) ?? available.first
    }

    func sortedMembers(_ members: [WorkspaceMember]) -> [WorkspaceMember] {
        members.sorted { lhs, rhs in
            let lhsRank = memberSortRank(for: lhs)
            let rhsRank = memberSortRank(for: rhs)
            if lhsRank != rhsRank {
                return lhsRank < rhsRank
            }

            let lhsName = displayName(for: lhs).localizedLowercase
            let rhsName = displayName(for: rhs).localizedLowercase
            if lhsName != rhsName {
                return lhsName < rhsName
            }

            return lhs.userId.uuidString < rhs.userId.uuidString
        }
    }

    private func memberSortRank(for member: WorkspaceMember) -> Int {
        let statusRank: Int
        switch member.status {
        case .active:
            statusRank = 0
        case .pending:
            statusRank = 1
        }

        let roleRank: Int
        switch member.role {
        case .owner:
            roleRank = 0
        case .member:
            roleRank = 1
        case .viewer:
            roleRank = 2
        }

        return (statusRank * 10) + roleRank
    }
}

enum WorkspaceCollaborationError: LocalizedError {
    case invalidEmail
    case userNotFound
    case cannotInviteYourself
    case alreadyMemberOrInvited

    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Gecerli bir e-posta girin."
        case .userNotFound:
            return "Bu e-posta ile eslesen kullanici bulunamadi."
        case .cannotInviteYourself:
            return "Kendinizi davet edemezsiniz."
        case .alreadyMemberOrInvited:
            return "Bu kullanici zaten uye veya bekleyen davet durumunda."
        }
    }
}

private extension Array {
    func asyncCompactMap<T>(
        _ transform: (Element) async throws -> T?
    ) async throws -> [T] {
        var result: [T] = []
        for element in self {
            if let value = try await transform(element) {
                result.append(value)
            }
        }
        return result
    }
}
