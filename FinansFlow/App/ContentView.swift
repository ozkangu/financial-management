import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }

            TransactionListView()
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

            MoreView()
                .tabItem {
                    Label("Daha Fazla", systemImage: "ellipsis.circle.fill")
                }
        }
    }
}

#Preview {
    ContentView()
}
