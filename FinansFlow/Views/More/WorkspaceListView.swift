import SwiftUI

struct WorkspaceListView: View {
    @Environment(AuthService.self) private var authService
    @Bindable var viewModel: WorkspaceViewModel

    @State private var showCreateSheet = false
    @State private var showEditSheet = false
    @State private var editingWorkspace: Workspace?
    @State private var newWorkspaceName = ""

    var body: some View {
        List {
            Section("Workspace'lerim") {
                ForEach(viewModel.workspaces) { workspace in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(workspace.name)
                                .font(.headline)
                            if workspace.id == viewModel.activeWorkspace?.id {
                                Text("Aktif")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            }
                        }
                        Spacer()
                        if workspace.ownerId == authService.currentUser?.id {
                            Image(systemName: "crown.fill")
                                .foregroundStyle(.orange)
                                .font(.caption)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.activeWorkspace = workspace
                    }
                    .swipeActions(edge: .trailing) {
                        if workspace.ownerId == authService.currentUser?.id {
                            Button(role: .destructive) {
                                Task { try? await viewModel.deleteWorkspace(workspace) }
                            } label: {
                                Label("Sil", systemImage: "trash")
                            }

                            Button {
                                editingWorkspace = workspace
                                newWorkspaceName = workspace.name
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
                    try? await viewModel.createWorkspace(name: newWorkspaceName, userId: userId)
                }
            }
            Button("İptal", role: .cancel) {}
        }
        .alert("Workspace Düzenle", isPresented: $showEditSheet) {
            TextField("Yeni Ad", text: $newWorkspaceName)
            Button("Kaydet") {
                guard var existingWorkspace = editingWorkspace else { return }
                existingWorkspace.name = newWorkspaceName
                Task { try? await viewModel.updateWorkspace(existingWorkspace) }
            }
            Button("İptal", role: .cancel) {}
        }
    }
}
