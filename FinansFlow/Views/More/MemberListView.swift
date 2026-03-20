import SwiftUI

struct MemberListView: View {
    @Environment(AuthService.self) private var authService
    @Bindable var viewModel: WorkspaceViewModel

    @State private var showInviteSheet = false
    @State private var inviteEmail = ""

    var body: some View {
        List {
            Section {
                ForEach(viewModel.members) { member in
                    HStack {
                        Image(systemName: member.role == .owner ? "crown.fill" : "person.fill")
                            .foregroundStyle(member.role == .owner ? .orange : .secondary)
                        VStack(alignment: .leading) {
                            Text(viewModel.displayName(for: member))
                                .font(.headline)
                            Text(viewModel.subtitle(for: member))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if member.status == .pending {
                            Text("Bekliyor")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.yellow.opacity(0.2))
                                .clipShape(Capsule())
                        }
                    }
                    .swipeActions {
                        if viewModel.activeWorkspace?.ownerId == authService.currentUser?.id,
                           member.userId != authService.currentUser?.id {
                            Button(role: .destructive) {
                                Task {
                                    do {
                                        try await viewModel.removeMember(memberId: member.id)
                                    } catch {
                                        viewModel.errorMessage = error.localizedDescription
                                    }
                                }
                            } label: {
                                Label("Çıkar", systemImage: "person.badge.minus")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Üyeler")
        .toolbar {
            if viewModel.activeWorkspace?.ownerId == authService.currentUser?.id {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        inviteEmail = ""
                        showInviteSheet = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                    }
                }
            }
        }
        .alert("Üye Davet Et", isPresented: $showInviteSheet) {
            TextField("E-posta", text: $inviteEmail)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
            Button("Davet Et") {
                guard
                    let currentUserId = authService.currentUser?.id,
                    let workspaceId = viewModel.activeWorkspace?.id
                else { return }
                Task {
                    do {
                        try await viewModel.inviteMember(
                            email: inviteEmail,
                            workspaceId: workspaceId,
                            currentUserId: currentUserId
                        )
                    } catch {
                        viewModel.errorMessage = error.localizedDescription
                    }
                }
            }
            Button("İptal", role: .cancel) {}
        } message: {
            Text("Davet edeceğiniz kişinin e-postasını girin")
        }
        .alert("Islem Basarisiz", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "Bilinmeyen hata")
        }
        .task(id: viewModel.activeWorkspace?.id) {
            await viewModel.loadMembers()
        }
    }
}
