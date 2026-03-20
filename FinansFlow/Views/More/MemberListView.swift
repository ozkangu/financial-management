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
                            Text(member.userId.uuidString.prefix(8) + "...")
                                .font(.headline)
                            Text(member.role.rawValue.capitalized)
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
                                Task { try? await viewModel.removeMember(memberId: member.id) }
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
                // In a real app, resolve email to userId via Supabase
                // For now this is a placeholder
            }
            Button("İptal", role: .cancel) {}
        } message: {
            Text("Davet edeceğiniz kişinin e-postasını girin")
        }
        .task {
            await viewModel.loadMembers()
        }
    }
}
