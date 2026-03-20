import SwiftUI

struct MoreView: View {
    @Environment(AuthService.self) private var authService
    @Bindable var workspaceVM: WorkspaceViewModel
    @Bindable var categoryVM: CategoryViewModel

    init(workspaceVM: WorkspaceViewModel = WorkspaceViewModel(),
         categoryVM: CategoryViewModel = CategoryViewModel()) {
        self.workspaceVM = workspaceVM
        self.categoryVM = categoryVM
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Finans") {
                    NavigationLink {
                        CategoryListView(
                            viewModel: categoryVM,
                            workspaceId: workspaceVM.activeWorkspace?.id ?? UUID()
                        )
                    } label: {
                        Label("Kategoriler", systemImage: "folder.fill")
                    }

                    NavigationLink {
                        Text("Pasif Gelirler")
                    } label: {
                        Label("Pasif Gelirler", systemImage: "chart.bar.fill")
                    }

                    NavigationLink {
                        Text("Borçlar")
                    } label: {
                        Label("Borçlar", systemImage: "creditcard.fill")
                    }
                }

                Section("Workspace") {
                    NavigationLink {
                        WorkspaceListView(viewModel: workspaceVM)
                    } label: {
                        Label("Workspace'ler", systemImage: "person.2.fill")
                    }

                    NavigationLink {
                        MemberListView(viewModel: workspaceVM)
                    } label: {
                        Label("Üyeler", systemImage: "person.badge.plus")
                    }
                }

                Section("Uygulama") {
                    NavigationLink {
                        Text("Ayarlar")
                    } label: {
                        Label("Ayarlar", systemImage: "gearshape.fill")
                    }

                    Button(role: .destructive) {
                        Task { await authService.signOut() }
                    } label: {
                        Label("Çıkış Yap", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Daha Fazla")
        }
    }
}

#Preview {
    MoreView()
        .environment(AuthService())
}
