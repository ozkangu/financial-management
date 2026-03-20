import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Text("Dashboard")
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }

            Text("Transactions")
                .tabItem {
                    Label("İşlemler", systemImage: "arrow.left.arrow.right")
                }

            Text("Investments")
                .tabItem {
                    Label("Yatırımlar", systemImage: "chart.pie.fill")
                }

            Text("Net Worth")
                .tabItem {
                    Label("Varlık", systemImage: "banknote.fill")
                }

            Text("More")
                .tabItem {
                    Label("Daha Fazla", systemImage: "ellipsis.circle.fill")
                }
        }
    }
}

#Preview {
    ContentView()
}
