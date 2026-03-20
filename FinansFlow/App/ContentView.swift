import SwiftUI

struct ContentView: View {
    @Environment(AuthService.self) private var authService
    @State private var workspaceVM = WorkspaceViewModel()
    @State private var categoryVM = CategoryViewModel()
    @State private var transactionVM = TransactionViewModel()

    var body: some View {
        TabView {
            DashboardView(
                transactionVM: transactionVM,
                categoryVM: categoryVM,
                workspaceVM: workspaceVM
            )
            .tabItem {
                Label("Dashboard", systemImage: "chart.bar.fill")
            }

            TransactionListView(
                transactionVM: transactionVM,
                categoryVM: categoryVM,
                workspaceId: workspaceVM.activeWorkspace?.id ?? UUID()
            )
            .tabItem {
                Label("İşlemler", systemImage: "arrow.left.arrow.right")
            }

            InvestmentListView()
                .tabItem {
                    Label("Yatırımlar", systemImage: "chart.pie.fill")
                }

            NetWorthView()
                .tabItem {
                    Label("Varlık", systemImage: "banknote.fill")
                }

            MoreView(
                workspaceVM: workspaceVM,
                categoryVM: categoryVM
            )
            .tabItem {
                Label("Daha Fazla", systemImage: "ellipsis.circle.fill")
            }
        }
        .task {
            guard let userId = authService.currentUser?.id,
                  let name = authService.currentUser?.name else { return }
            await workspaceVM.ensurePersonalWorkspace(userId: userId, userName: name)
            if let wsId = workspaceVM.activeWorkspace?.id {
                await categoryVM.loadCategories(workspaceId: wsId)
                await transactionVM.loadTransactions(workspaceId: wsId, reset: true)
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(AuthService())
}
