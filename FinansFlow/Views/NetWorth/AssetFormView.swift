import SwiftUI
import SwiftData

struct AssetFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: NetWorthViewModel

    var editingAsset: Asset?

    @State private var name = ""
    @State private var type: AssetType = .bankAccount
    @State private var value = ""
    @State private var notes = ""
    @State private var showError = false
    @State private var errorText = ""

    private var isEditing: Bool { editingAsset != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Varlık Bilgileri") {
                    TextField("Varlık Adı", text: $name)

                    Picker("Tür", selection: $type) {
                        ForEach(AssetType.allCases, id: \.self) { t in
                            HStack {
                                Image(systemName: t.icon)
                                Text(t.displayName)
                            }
                            .tag(t)
                        }
                    }

                    TextField("Değer", text: $value)
                        .keyboardType(.decimalPad)
                }

                Section("Not") {
                    TextField("Not (opsiyonel)", text: $notes, axis: .vertical)
                        .lineLimit(3)
                }
            }
            .navigationTitle(isEditing ? "Varlık Düzenle" : "Varlık Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") { save() }
                    .disabled(name.isEmpty || value.isEmpty)
                }
            }
            .onAppear { loadExisting() }
            .alert("Hata", isPresented: $showError) {
                Button("Tamam") {}
            } message: {
                Text(errorText)
            }
        }
    }

    private func loadExisting() {
        guard let asset = editingAsset else { return }
        name = asset.name
        type = asset.type
        value = String(asset.value)
        notes = asset.notes ?? ""
    }

    private func save() {
        guard let val = Double(value.replacingOccurrences(of: ",", with: ".")) else {
            errorText = "Geçersiz değer"
            showError = true
            return
        }

        if let existing = editingAsset {
            existing.name = name
            existing.type = type
            existing.value = val
            existing.notes = notes.isEmpty ? nil : notes
            viewModel.updateAsset(existing, context: modelContext)
        } else {
            viewModel.createAsset(
                context: modelContext,
                name: name,
                type: type,
                value: val,
                currency: AppConstants.defaultCurrency,
                notes: notes.isEmpty ? nil : notes
            )
        }
        dismiss()
    }
}
