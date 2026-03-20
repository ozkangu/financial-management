import SwiftUI

struct TransactionListView: View {
    var body: some View {
        NavigationStack {
            List {
                Text("İşlem listesi buraya gelecek")
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("İşlemler")
        }
    }
}

#Preview {
    TransactionListView()
}
