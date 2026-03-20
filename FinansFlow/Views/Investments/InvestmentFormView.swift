import SwiftUI
import SwiftData

struct InvestmentFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: InvestmentViewModel

    var editingInvestment: Investment?

    @State private var name = ""
    @State private var type: InvestmentType = .stock
    @State private var purchaseDate = Date()
    @State private var unitCost = ""
    @State private var quantity = ""
    @State private var currentValue = ""
    @State private var currency = AppConstants.defaultCurrency
    @State private var institution = ""
    @State private var notes = ""
    @State private var showError = false
    @State private var errorText = ""

    private var isEditing: Bool { editingInvestment != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Yatırım Bilgileri") {
                    TextField("Varlık Adı", text: $name)

                    Picker("Tür", selection: $type) {
                        ForEach(InvestmentType.allCases, id: \.self) { t in
                            HStack {
                                Image(systemName: t.icon)
                                Text(t.displayName)
                            }
                            .tag(t)
                        }
                    }

                    DatePicker("Alış Tarihi", selection: $purchaseDate, displayedComponents: .date)
                }

                Section("Değerler") {
                    TextField("Birim Maliyet", text: $unitCost)
                        .keyboardType(.decimalPad)
                    TextField("Miktar/Adet", text: $quantity)
                        .keyboardType(.decimalPad)
                    TextField("Güncel Değer", text: $currentValue)
                        .keyboardType(.decimalPad)

                    Picker("Para Birimi", selection: $currency) {
                        ForEach(AppConstants.CurrencyOptions.all, id: \.self) { c in
                            Text(c).tag(c)
                        }
                    }
                }

                Section("Ek Bilgiler") {
                    TextField("Platform/Kurum (opsiyonel)", text: $institution)
                    TextField("Not (opsiyonel)", text: $notes, axis: .vertical)
                        .lineLimit(3)
                }
            }
            .navigationTitle(isEditing ? "Yatırım Düzenle" : "Yatırım Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") { save() }
                    .disabled(name.isEmpty || currentValue.isEmpty)
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
        guard let inv = editingInvestment else { return }
        name = inv.name
        type = inv.type
        purchaseDate = inv.purchaseDate ?? Date()
        unitCost = String(inv.unitCost)
        quantity = String(inv.quantity)
        currentValue = String(inv.currentValue)
        currency = inv.currency
        institution = inv.institution ?? ""
        notes = inv.notes ?? ""
    }

    private func save() {
        let cost = Double(unitCost.replacingOccurrences(of: ",", with: ".")) ?? 0
        let qty = Double(quantity.replacingOccurrences(of: ",", with: ".")) ?? 0
        let value = Double(currentValue.replacingOccurrences(of: ",", with: ".")) ?? 0

        if let existing = editingInvestment {
            existing.name = name
            existing.type = type
            existing.purchaseDate = purchaseDate
            existing.unitCost = cost
            existing.quantity = qty
            existing.currentValue = value
            existing.institution = institution.isEmpty ? nil : institution
            existing.notes = notes.isEmpty ? nil : notes
            viewModel.updateInvestment(existing, context: modelContext)
        } else {
            viewModel.createInvestment(
                context: modelContext,
                name: name,
                type: type,
                purchaseDate: purchaseDate,
                unitCost: cost,
                quantity: qty,
                currentValue: value,
                currency: currency,
                institution: institution.isEmpty ? nil : institution,
                notes: notes.isEmpty ? nil : notes
            )
        }
        dismiss()
    }
}
