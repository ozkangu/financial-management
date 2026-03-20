import SwiftUI

struct ContentView: View {
    @Environment(AuthService.self) private var authService
    @State private var workspaceVM = WorkspaceViewModel()
    @State private var categoryVM = CategoryViewModel()
    @State private var transactionVM = TransactionViewModel()
    @State private var investmentVM = InvestmentViewModel()
    @State private var passiveIncomeVM = PassiveIncomeViewModel()
    @State private var liabilityVM = LiabilityViewModel()
    @State private var netWorthVM = NetWorthViewModel()

    private var wsId: UUID {
        workspaceVM.activeWorkspace?.id ?? UUID()
    }

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
                workspaceId: wsId
            )
            .tabItem {
                Label("İşlemler", systemImage: "arrow.left.arrow.right")
            }

            InvestmentListView(
                viewModel: investmentVM,
                workspaceId: wsId
            )
            .tabItem {
                Label("Yatırımlar", systemImage: "chart.pie.fill")
            }

            NetWorthView(
                netWorthVM: netWorthVM,
                liabilityVM: liabilityVM,
                workspaceId: wsId
            )
            .tabItem {
                Label("Varlık", systemImage: "banknote.fill")
            }

            MoreView(
                workspaceVM: workspaceVM,
                categoryVM: categoryVM,
                investmentVM: investmentVM,
                passiveIncomeVM: passiveIncomeVM,
                liabilityVM: liabilityVM
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
                await investmentVM.loadInvestments(workspaceId: wsId)
                await passiveIncomeVM.loadPassiveIncomes(workspaceId: wsId)
                await liabilityVM.loadLiabilities(workspaceId: wsId)
                await netWorthVM.loadAssets(workspaceId: wsId)
                await netWorthVM.loadSnapshots(workspaceId: wsId)
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(AuthService())
}
