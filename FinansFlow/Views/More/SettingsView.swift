import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @AppStorage("biometricLockEnabled") private var biometricLockEnabled = false
    @AppStorage("preferredCurrency") private var preferredCurrency = AppConstants.defaultCurrency
    @Bindable var transactionVM: TransactionViewModel
    @Bindable var categoryVM: CategoryViewModel

    @State private var showExportSheet = false
    @State private var exportURL: URL?
    @State private var exportError: String?

    var body: some View {
        Form {
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
                        Text("FinansFlow, kişisel finansınızı yönetmeniz için tasarlanmış bir uygulamadır. Gelir, gider, yatırım ve net varlık takibinizi tek bir yerden yapabilirsiniz.")
                            .padding()
                    }
                    .navigationTitle("Gizlilik Politikası")
                } label: {
                    Label("Gizlilik Politikası", systemImage: "hand.raised.fill")
                }

                NavigationLink {
                    ScrollView {
                        Text("FinansFlow kullanım koşulları: Bu uygulamayı kullanarak, verilerinizin cihazınızda güvenli bir şekilde saklanacağını kabul etmiş olursunuz.")
                            .padding()
                    }
                    .navigationTitle("Kullanım Koşulları")
                } label: {
                    Label("Kullanım Koşulları", systemImage: "doc.text.fill")
                }

                HStack {
                    Text("Versiyon")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
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
        .alert("Islem Basarisiz", isPresented: Binding(
            get: { exportError != nil },
            set: { if !$0 { exportError = nil } }
        )) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(exportError ?? "Bilinmeyen hata")
        }
    }

    private func exportCSV() {
        let csv = CSVExportBuilder.transactionsCSV(
            transactions: transactionVM.transactions,
            categories: categoryVM.categories
        )
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("finansflow-transactions.csv")

        do {
            try csv.write(to: tempURL, atomically: true, encoding: .utf8)
            exportURL = tempURL
            showExportSheet = true
        } catch {
            exportError = error.localizedDescription
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

enum CSVExportBuilder {
    static func transactionsCSV(
        transactions: [Transaction],
        categories: [Category]
    ) -> String {
        let header = [
            "Tarih",
            "Tur",
            "Tutar",
            "Para Birimi",
            "Kategori",
            "Aciklama"
        ].map(csvField).joined(separator: ",")

        let rows = transactions
            .sorted { $0.date > $1.date }
            .map { transaction -> String in
                let categoryName = transaction.category?.name
                    ?? categories.first(where: { $0.id == transaction.category?.id })?.name
                    ?? "Kategori Yok"

                return [
                    transaction.date.displayString,
                    transaction.type == .income ? "Gelir" : "Gider",
                    transaction.amount.formatted(),
                    transaction.currency,
                    categoryName,
                    transaction.descriptionText ?? ""
                ]
                .map(csvField)
                .joined(separator: ",")
            }

        return ([header] + rows).joined(separator: "\n")
    }

    private static func csvField(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }
}
