import SwiftUI

struct MoreView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Finans") {
                    Label("Kategoriler", systemImage: "folder.fill")
                    Label("Pasif Gelirler", systemImage: "chart.bar.fill")
                    Label("Borçlar", systemImage: "creditcard.fill")
                }

                Section("Uygulama") {
                    Label("Ayarlar", systemImage: "gearshape.fill")
                }
            }
            .navigationTitle("Daha Fazla")
        }
    }
}

#Preview {
    MoreView()
}
