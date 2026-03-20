import SwiftUI

struct NetWorthView: View {
    var body: some View {
        NavigationStack {
            List {
                Text("Net varlık bilgileri buraya gelecek")
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Net Varlık")
        }
    }
}

#Preview {
    NetWorthView()
}
