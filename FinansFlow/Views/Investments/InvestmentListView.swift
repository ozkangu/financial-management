import SwiftUI

struct InvestmentListView: View {
    var body: some View {
        NavigationStack {
            List {
                Text("Yatırım portföyü buraya gelecek")
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Yatırımlar")
        }
    }
}

#Preview {
    InvestmentListView()
}
