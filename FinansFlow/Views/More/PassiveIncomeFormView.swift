import SwiftUI
import SwiftData

struct PassiveIncomeFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: PassiveIncomeViewModel
    @Bindable var investmentVM: InvestmentViewModel

    var editingIncome: PassiveIncome?

    @State private var selectedInvestment: Investment?
    @State private var type: PassiveIncomeType = .dividend
    @State private var amount = ""
    @State private var frequency: PaymentFrequency = .monthly
    @State private var nextPaymentDate = Date()
    @State private var descriptionText = ""
    @State private var showError = false
    @State private var errorText = ""

    private var isEditing: Bool { editingIncome != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Tür") {
                    Picker("Gelir Türü", selection: $type) {
                        ForEach(PassiveIncomeType.allCases, id: \.self) { t in
                            HStack {
                                Image(systemName: t.icon)
                                Text(t.displayName)
                            }
                            .tag(t)
                        }
                    }

                    Picker("Bağlı Yatırım", selection: $selectedInvestment) {
                        Text("Yok").tag(Investment?.none)
                        ForEach(investmentVM.investments) { inv in
                            Text(inv.name).tag(Investment?.some(inv))
                        }
                    }
                }

                Section("Tutar & Frekans") {
                    TextField("Tutar", text: $amount)
                        .keyboardType(.decimalPad)

                    Picker("Frekans", selection: $frequency) {
                        ForEach(PaymentFrequency.allCases, id: \.self) { f in
                            Text(f.displayName).tag(f)
                        }
                    }

                    DatePicker("Sonraki Ödeme Tarihi", selection: $nextPaymentDate, displayedComponents: .date)
                }

                Section("Açıklama") {
                    TextField("Açıklama (opsiyonel)", text: $descriptionText)
                }
            }
            .navigationTitle(isEditing ? "Pasif Gelir Düzenle" : "Pasif Gelir Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") { save() }
                    .disabled(amount.isEmpty)
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
        guard let inc = editingIncome else { return }
        selectedInvestment = inc.investment
        type = inc.type
        amount = String(inc.amount)
        frequency = inc.frequency
        nextPaymentDate = inc.nextPaymentDate ?? Date()
        descriptionText = inc.descriptionText ?? ""
    }

    private func save() {
        guard let amountValue = Double(amount.replacingOccurrences(of: ",", with: ".")) else {
            errorText = "Geçersiz tutar"
            showError = true
            return
        }

        if let existing = editingIncome {
            existing.investment = selectedInvestment
            existing.type = type
            existing.amount = amountValue
            existing.frequency = frequency
            existing.nextPaymentDate = nextPaymentDate
            existing.descriptionText = descriptionText.isEmpty ? nil : descriptionText
            viewModel.updatePassiveIncome(existing, context: modelContext)
        } else {
            viewModel.createPassiveIncome(
                context: modelContext,
                investment: selectedInvestment,
                type: type,
                amount: amountValue,
                currency: AppConstants.defaultCurrency,
                frequency: frequency,
                nextPaymentDate: nextPaymentDate,
                descriptionText: descriptionText.isEmpty ? nil : descriptionText
            )
        }
        dismiss()
    }
}
