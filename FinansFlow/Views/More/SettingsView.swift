import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(AuthService.self) private var authService
    let workspace: Workspace?
    @Bindable var transactionVM: TransactionViewModel
    @Bindable var categoryVM: CategoryViewModel
    @AppStorage("biometricLockEnabled") private var biometricLockEnabled = false
    @AppStorage("preferredCurrency") private var preferredCurrency = AppConstants.defaultCurrency

    @State private var showExportSheet = false
    @State private var exportURL: URL?
    @State private var exportErrorMessage: String?

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
        .alert("CSV Disa Aktarma Basarisiz", isPresented: Binding(
            get: { exportErrorMessage != nil },
            set: { if !$0 { exportErrorMessage = nil } }
        )) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(exportErrorMessage ?? "Bilinmeyen hata")
        }
    }

    private func exportCSV() {
        let csv = CSVExportBuilder.transactionsCSV(
            workspace: workspace,
            transactions: transactionVM.transactions,
            categories: categoryVM.categories
        )
        let filename = CSVExportBuilder.filename(for: workspace)
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        do {
            try csv.write(to: tempURL, atomically: true, encoding: .utf8)
        } catch {
            exportURL = nil
            exportErrorMessage = error.localizedDescription
            showExportSheet = false
            return
        }

        exportURL = tempURL
        showExportSheet = true
    }
}

enum CSVExportBuilder {
    static func filename(for workspace: Workspace?) -> String {
        let allowedCharacters = CharacterSet.alphanumerics
        let workspaceName = workspace?.name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .map { character -> String in
                let scalar = String(character).unicodeScalars.first
                guard let scalar, allowedCharacters.contains(scalar) || character == "-" || character == "_" else {
                    return "-"
                }
                return String(character)
            }
            .joined()
            .split(separator: "-", omittingEmptySubsequences: true)
            .joined(separator: "-")

        if let workspaceName, !workspaceName.isEmpty {
            return "finansflow-\(workspaceName)-transactions.csv"
        }

        return "finansflow-transactions.csv"
    }

    static func transactionsCSV(
        workspace: Workspace?,
        transactions: [Transaction],
        categories: [Category]
    ) -> String {
        let header = [
            "Workspace",
            "Tarih",
            "Tur",
            "Tutar",
            "Para Birimi",
            "Kategori",
            "Kapsam",
            "Aciklama"
        ]

        let categoryLookup = Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0.name) })
        let sortedTransactions = transactions.sorted { $0.date > $1.date }
        let rows = sortedTransactions.map { transaction in
            [
                workspace?.name ?? "",
                transaction.date.displayString,
                transaction.type == .income ? "Gelir" : "Gider",
                String(transaction.amount),
                transaction.currency,
                transaction.categoryId.flatMap { categoryLookup[$0] } ?? "",
                transaction.visibilityScope == .personal ? "Kisisel" : "Ortak",
                transaction.description ?? ""
            ]
        }

        return ([header] + rows)
            .map { row in row.map(escapeCSVField).joined(separator: ",") }
            .joined(separator: "\n")
    }

    private static func escapeCSVField(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
