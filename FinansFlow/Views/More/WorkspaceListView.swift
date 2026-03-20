import SwiftUI

struct WorkspaceListView: View {
    @Environment(AuthService.self) private var authService
    @Bindable var viewModel: WorkspaceViewModel

    @State private var showCreateSheet = false
    @State private var showEditSheet = false
    @State private var editingWorkspace: Workspace?
    @State private var newWorkspaceName = ""
    @State private var acceptedWorkspaceName: String?

    var body: some View {
        List {
            if !viewModel.pendingInvitations.isEmpty {
                Section("Bekleyen Davetler") {
                    ForEach(viewModel.pendingInvitations) { invitation in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(viewModel.workspaceName(for: invitation))
                                .font(.headline)
                            Text("Bu workspace sizi bekleyen uye olarak davet etti.")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Button("Daveti Kabul Et") {
                                guard let userId = authService.currentUser?.id else { return }
                                Task {
                                    do {
                                        try await viewModel.acceptInvitation(
                                            memberId: invitation.id,
                                            userId: userId
                                        )
                                        acceptedWorkspaceName = viewModel.activeWorkspace?.name
                                    } catch {
                                        viewModel.errorMessage = error.localizedDescription
                                    }
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            Section("Workspace'lerim") {
                ForEach(viewModel.workspaces) { ws in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(ws.name)
                                .font(.headline)
                            if ws.id == viewModel.activeWorkspace?.id {
                                Text("Aktif")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            }
                        }
                        Spacer()
                        if ws.ownerId == authService.currentUser?.id {
                            Image(systemName: "crown.fill")
                                .foregroundStyle(.orange)
                                .font(.caption)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.activeWorkspace = ws
                    }
                    .swipeActions(edge: .trailing) {
                        if ws.ownerId == authService.currentUser?.id {
                            Button(role: .destructive) {
                                Task {
                                    do {
                                        try await viewModel.deleteWorkspace(ws)
                                    } catch {
                                        viewModel.errorMessage = error.localizedDescription
                                    }
                                }
                            } label: {
                                Label("Sil", systemImage: "trash")
                            }

                            Button {
                                editingWorkspace = ws
                                newWorkspaceName = ws.name
                                showEditSheet = true
                            } label: {
                                Label("Düzenle", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                    }
                }
            }
        }
        .navigationTitle("Workspace'ler")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    newWorkspaceName = ""
                    showCreateSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .alert("Yeni Workspace", isPresented: $showCreateSheet) {
            TextField("Workspace Adı", text: $newWorkspaceName)
            Button("Oluştur") {
                guard let userId = authService.currentUser?.id else { return }
                Task {
                    do {
                        try await viewModel.createWorkspace(name: newWorkspaceName, userId: userId)
                    } catch {
                        viewModel.errorMessage = error.localizedDescription
                    }
                }
            }
            Button("İptal", role: .cancel) {}
        }
        .alert("Workspace Düzenle", isPresented: $showEditSheet) {
            TextField("Yeni Ad", text: $newWorkspaceName)
            Button("Kaydet") {
                guard var ws = editingWorkspace else { return }
                ws.name = newWorkspaceName
                Task {
                    do {
                        try await viewModel.updateWorkspace(ws)
                    } catch {
                        viewModel.errorMessage = error.localizedDescription
                    }
                }
            }
            Button("İptal", role: .cancel) {}
        }
        .alert("Islem Basarisiz", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "Bilinmeyen hata")
        }
        .alert("Davet Kabul Edildi", isPresented: Binding(
            get: { acceptedWorkspaceName != nil },
            set: { if !$0 { acceptedWorkspaceName = nil } }
        )) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text("\(acceptedWorkspaceName ?? "Workspace") aktif workspace olarak secildi.")
        }
        .task {
            guard let userId = authService.currentUser?.id else { return }
            await viewModel.loadWorkspaces(userId: userId)
        }
    }
}
