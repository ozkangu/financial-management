import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(AuthService.self) private var authService
    @AppStorage("biometricLockEnabled") private var biometricLockEnabled = false
    @AppStorage("preferredCurrency") private var preferredCurrency = AppConstants.defaultCurrency

    @State private var showExportSheet = false
    @State private var exportURL: URL?

    var body: some View {
        Form {
            Section("Profil") {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    VStack(alignment: .leading) {
                        Text(authService.currentUser?.name ?? String(localized: "Kullanıcı"))
                            .font(.headline)
                        Text(authService.currentUser?.email ?? "")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Genel") {
                Picker("Para Birimi", selection: $preferredCurrency) {
                    ForEach(AppConstants.CurrencyOptions.all, id: \.self) { currency in
                        Text(currency).tag(currency)
                    }
                }
            }

            Section("Güvenlik") {
                Toggle("Face ID / Touch ID Kilidi", isOn: $biometricLockEnabled)
            }

            Section("Veri") {
                Button {
                    exportCSV()
                } label: {
                    Label("Verileri Dışa Aktar (CSV)", systemImage: "square.and.arrow.up")
                }
            }

            Section("Hakkında") {
                NavigationLink {
                    ScrollView {
                        Text("FinansFlow, kişisel ve aile finansınızı yönetmeniz için tasarlanmış bir uygulamadır. Gelir, gider, yatırım ve net varlık takibinizi tek bir yerden yapabilirsiniz.")
                            .padding()
                    }
                    .navigationTitle("Gizlilik Politikası")
                } label: {
                    Label("Gizlilik Politikası", systemImage: "hand.raised.fill")
                }

                NavigationLink {
                    ScrollView {
                        Text("FinansFlow kullanım koşulları: Bu uygulamayı kullanarak, verilerinizin Supabase altyapısında güvenli bir şekilde saklanacağını kabul etmiş olursunuz.")
                            .padding()
                    }
                    .navigationTitle("Kullanım Koşulları")
                } label: {
                    Label("Kullanım Koşulları", systemImage: "doc.text.fill")
                }

                HStack {
                    Text("Versiyon")
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Ayarlar")
        .sheet(isPresented: $showExportSheet) {
            if let url = exportURL {
                ShareSheet(items: [url])
            }
        }
    }

    private func exportCSV() {
        // Create a simple CSV export placeholder
        let csv = String(localized: "Tarih,Tür,Tutar,Kategori,Açıklama") + "\n"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("finansflow_export.csv")
        try? csv.write(to: tempURL, atomically: true, encoding: .utf8)
        exportURL = tempURL
        showExportSheet = true
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
