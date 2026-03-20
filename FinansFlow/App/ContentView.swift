import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var categoryVM = CategoryViewModel()
    @State private var transactionVM = TransactionViewModel()
    @State private var investmentVM = InvestmentViewModel()
    @State private var passiveIncomeVM = PassiveIncomeViewModel()
    @State private var liabilityVM = LiabilityViewModel()
    @State private var netWorthVM = NetWorthViewModel()

    var body: some View {
        TabView {
            DashboardView(
                transactionVM: transactionVM,
                categoryVM: categoryVM,
                passiveIncomeVM: passiveIncomeVM,
                netWorthVM: netWorthVM,
                liabilityVM: liabilityVM
            )
            .tabItem {
                Label("Dashboard", systemImage: "chart.bar.fill")
            }

            TransactionListView(
                transactionVM: transactionVM,
                categoryVM: categoryVM
            )
            .tabItem {
                Label("İşlemler", systemImage: "arrow.left.arrow.right")
            }

            NetWorthView(
                netWorthVM: netWorthVM,
                liabilityVM: liabilityVM,
                investmentVM: investmentVM
            )
            .tabItem {
                Label("Servet", systemImage: "banknote.fill")
            }

            MoreView(
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
            CategorySeeder.seedIfNeeded(context: modelContext)
            categoryVM.loadCategories(context: modelContext)
            transactionVM.loadTransactions(context: modelContext)
            investmentVM.loadInvestments(context: modelContext)
            passiveIncomeVM.loadPassiveIncomes(context: modelContext)
            liabilityVM.loadLiabilities(context: modelContext)
            netWorthVM.loadAssets(context: modelContext)
            netWorthVM.loadSnapshots(context: modelContext)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [
            Category.self,
            Transaction.self,
            Investment.self,
            PassiveIncome.self,
            Asset.self,
            Liability.self,
            NetWorthSnapshot.self
        ], inMemory: true)
}
