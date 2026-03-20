import SwiftUI

struct AssetFormView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: NetWorthViewModel

    let workspaceId: UUID
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
                    Button("Kaydet") {
                        Task { await save() }
                    }
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

    private func save() async {
        guard let val = Double(value.replacingOccurrences(of: ",", with: ".")) else {
            errorText = "Geçersiz değer"
            showError = true
            return
        }

        do {
            if var existing = editingAsset {
                existing.name = name
                existing.type = type
                existing.value = val
                existing.notes = notes.isEmpty ? nil : notes
                try await viewModel.updateAsset(existing)
            } else {
                guard let userId = authService.currentUser?.id else { return }
                try await viewModel.createAsset(
                    workspaceId: workspaceId,
                    userId: userId,
                    name: name,
                    type: type,
                    value: val,
                    currency: AppConstants.defaultCurrency,
                    notes: notes.isEmpty ? nil : notes
                )
            }
            dismiss()
        } catch {
            errorText = error.localizedDescription
            showError = true
        }
    }
}
