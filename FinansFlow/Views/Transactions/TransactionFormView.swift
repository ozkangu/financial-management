import SwiftUI

struct TransactionFormView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: TransactionViewModel
    @Bindable var categoryVM: CategoryViewModel

    let workspaceId: UUID
    var editingTransaction: Transaction?
    var transactionType: TransactionType = .expense

    @State private var amount = ""
    @State private var date = Date()
    @State private var categoryId: UUID?
    @State private var description = ""
    @State private var paymentMethod = ""
    @State private var visibilityScope: VisibilityScope = .personal
    @State private var isRecurring = false
    @State private var recurrenceInterval: RecurrenceInterval = .monthly
    @State private var type: TransactionType = .expense
    @State private var showError = false
    @State private var errorText = ""

    private var isEditing: Bool { editingTransaction != nil }

    private let paymentMethods = ["Nakit", "Kredi Kartı", "Banka Kartı", "Havale/EFT", "Diğer"]

    private func localizedPaymentMethod(_ method: String) -> String {
        String(localized: String.LocalizationValue(method))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Tutar") {
                    TextField("0,00", text: $amount)
                        .keyboardType(.decimalPad)
                        .font(.title.bold())
                }

                Section("Detaylar") {
                    DatePicker("Tarih", selection: $date, displayedComponents: .date)

                    let relevantCategories = categoryVM.categories.filter { category in
                        category.type == (type == .income ? .income : .expense)
                    }
                    Picker("Kategori", selection: $categoryId) {
                        Text("Seçiniz").tag(UUID?.none)
                        ForEach(relevantCategories) { category in
                            HStack {
                                Image(systemName: category.icon)
                                Text(category.parentId != nil ? "  \(category.name)" : category.name)
                            }
                            .tag(UUID?.some(category.id))
                        }
                    }

                    TextField("Açıklama (opsiyonel)", text: $description)

                    if type == .expense {
                        Picker("Ödeme Yöntemi", selection: $paymentMethod) {
                            Text("Seçiniz").tag("")
                            ForEach(paymentMethods, id: \.self) { method in
                                Text(localizedPaymentMethod(method)).tag(method)
                            }
                        }
                    }
                }

                Section("Kapsam") {
                    Picker("Görünürlük", selection: $visibilityScope) {
                        Text("Kişisel").tag(VisibilityScope.personal)
                        Text("Ortak").tag(VisibilityScope.shared)
                    }
                    .pickerStyle(.segmented)
                }

                Section("Tekrarlama") {
                    Toggle("Tekrarlayan İşlem", isOn: $isRecurring)
                    if isRecurring {
                        Picker("Periyot", selection: $recurrenceInterval) {
                            Text("Haftalık").tag(RecurrenceInterval.weekly)
                            Text("Aylık").tag(RecurrenceInterval.monthly)
                            Text("Yıllık").tag(RecurrenceInterval.yearly)
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "İşlem Düzenle" : (type == .income ? "Gelir Ekle" : "Gider Ekle"))
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
        guard let existingTransaction = editingTransaction else {
            type = transactionType
            return
        }
        type = existingTransaction.type
        amount = String(existingTransaction.amount)
        date = existingTransaction.date
        categoryId = existingTransaction.categoryId
        description = existingTransaction.description ?? ""
        paymentMethod = existingTransaction.paymentMethod ?? ""
        visibilityScope = existingTransaction.visibilityScope
        isRecurring = existingTransaction.isRecurring
        recurrenceInterval = existingTransaction.recurrenceInterval ?? .monthly
    }

    private func save() async {
        guard let amountValue = Double(amount.replacingOccurrences(of: ",", with: ".")) else {
            errorText = "Geçersiz tutar"
            showError = true
            return
        }

        do {
            if var existing = editingTransaction {
                existing.amount = amountValue
                existing.date = date
                existing.categoryId = categoryId
                existing.description = description.isEmpty ? nil : description
                existing.paymentMethod = paymentMethod.isEmpty ? nil : paymentMethod
                existing.visibilityScope = visibilityScope
                existing.isRecurring = isRecurring
                existing.recurrenceInterval = isRecurring ? recurrenceInterval : nil
                try await viewModel.updateTransaction(existing)
            } else {
                guard let userId = authService.currentUser?.id else { return }
                try await viewModel.createTransaction(
                    workspaceId: workspaceId,
                    userId: userId,
                    type: type,
                    categoryId: categoryId,
                    amount: amountValue,
                    date: date,
                    description: description.isEmpty ? nil : description,
                    paymentMethod: paymentMethod.isEmpty ? nil : paymentMethod,
                    visibilityScope: visibilityScope,
                    isRecurring: isRecurring,
                    recurrenceInterval: isRecurring ? recurrenceInterval : nil,
                    tags: nil
                )
            }
            dismiss()
        } catch {
            errorText = error.localizedDescription
            showError = true
        }
    }
}
