import SwiftUI

struct PassiveIncomeFormView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: PassiveIncomeViewModel
    @Bindable var investmentVM: InvestmentViewModel

    let workspaceId: UUID
    var editingIncome: PassiveIncome?

    @State private var investmentId: UUID?
    @State private var type: PassiveIncomeType = .dividend
    @State private var amount = ""
    @State private var frequency: PaymentFrequency = .monthly
    @State private var nextPaymentDate = Date()
    @State private var description = ""
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

                    Picker("Bağlı Yatırım", selection: $investmentId) {
                        Text("Yok").tag(UUID?.none)
                        ForEach(investmentVM.investments) { inv in
                            Text(inv.name).tag(UUID?.some(inv.id))
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
                    TextField("Açıklama (opsiyonel)", text: $description)
                }
            }
            .navigationTitle(isEditing ? "Pasif Gelir Düzenle" : "Pasif Gelir Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        Task { await save() }
                    }
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
        investmentId = inc.investmentId
        type = inc.type
        amount = String(inc.amount)
        frequency = inc.frequency
        nextPaymentDate = inc.nextPaymentDate ?? Date()
        description = inc.description ?? ""
    }

    private func save() async {
        guard let amountValue = Double(amount.replacingOccurrences(of: ",", with: ".")) else {
            errorText = "Geçersiz tutar"
            showError = true
            return
        }

        do {
            if var existing = editingIncome {
                existing.investmentId = investmentId
                existing.type = type
                existing.amount = amountValue
                existing.frequency = frequency
                existing.nextPaymentDate = nextPaymentDate
                existing.description = description.isEmpty ? nil : description
                try await viewModel.updatePassiveIncome(existing)
            } else {
                guard let userId = authService.currentUser?.id else { return }
                try await viewModel.createPassiveIncome(
                    workspaceId: workspaceId,
                    userId: userId,
                    investmentId: investmentId,
                    type: type,
                    amount: amountValue,
                    currency: AppConstants.defaultCurrency,
                    frequency: frequency,
                    nextPaymentDate: nextPaymentDate,
                    description: description.isEmpty ? nil : description
                )
            }
            dismiss()
        } catch {
            errorText = error.localizedDescription
            showError = true
        }
    }
}
