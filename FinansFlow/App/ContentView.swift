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

    private var workspaceDataLoader: WorkspaceDataLoader {
        WorkspaceDataLoader(
            loadCategories: { workspaceId in
                await categoryVM.loadCategories(workspaceId: workspaceId)
            },
            loadTransactions: { workspaceId in
                await transactionVM.loadTransactions(workspaceId: workspaceId, reset: true)
            },
            loadInvestments: { workspaceId in
                await investmentVM.loadInvestments(workspaceId: workspaceId)
            },
            loadPassiveIncomes: { workspaceId in
                await passiveIncomeVM.loadPassiveIncomes(workspaceId: workspaceId)
            },
            loadLiabilities: { workspaceId in
                await liabilityVM.loadLiabilities(workspaceId: workspaceId)
            },
            loadAssets: { workspaceId in
                await netWorthVM.loadAssets(workspaceId: workspaceId)
            },
            loadSnapshots: { workspaceId in
                await netWorthVM.loadSnapshots(workspaceId: workspaceId)
            }
        )
    }

    var body: some View {
        TabView {
            DashboardView(
                transactionVM: transactionVM,
                categoryVM: categoryVM,
                workspaceVM: workspaceVM,
                passiveIncomeVM: passiveIncomeVM,
                netWorthVM: netWorthVM,
                liabilityVM: liabilityVM
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
                transactionVM: transactionVM,
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
        }
        .task(id: workspaceVM.activeWorkspace?.id) {
            guard let workspaceId = workspaceVM.activeWorkspace?.id else { return }
            await workspaceDataLoader.reload(workspaceId: workspaceId)
        }
    }
}

#Preview {
    ContentView()
        .environment(AuthService())
}
