import SwiftUI
import SwiftData

struct TransactionFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: TransactionViewModel
    @Bindable var categoryVM: CategoryViewModel

    var editingTransaction: Transaction?
    var transactionType: TransactionType = .expense

    @State private var amount = ""
    @State private var date = Date()
    @State private var selectedCategory: Category?
    @State private var descriptionText = ""
    @State private var paymentMethod = ""
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

                    let relevantCategories = categoryVM.categories.filter { $0.type == (type == .income ? .income : .expense) }
                    Picker("Kategori", selection: $selectedCategory) {
                        Text("Seçiniz").tag(Category?.none)
                        ForEach(relevantCategories) { cat in
                            HStack {
                                Image(systemName: cat.icon)
                                Text(cat.parent != nil ? "  \(cat.name)" : cat.name)
                            }
                            .tag(Category?.some(cat))
                        }
                    }

                    TextField("Açıklama (opsiyonel)", text: $descriptionText)

                    if type == .expense {
                        Picker("Ödeme Yöntemi", selection: $paymentMethod) {
                            Text("Seçiniz").tag("")
                            ForEach(paymentMethods, id: \.self) { method in
                                Text(localizedPaymentMethod(method)).tag(method)
                            }
                        }
                    }
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
        guard let tx = editingTransaction else {
            type = transactionType
            return
        }
        type = tx.type
        amount = String(tx.amount)
        date = tx.date
        selectedCategory = tx.category
        descriptionText = tx.descriptionText ?? ""
        paymentMethod = tx.paymentMethod ?? ""
        isRecurring = tx.isRecurring
        recurrenceInterval = tx.recurrenceInterval ?? .monthly
    }

    private func save() {
        guard let amountValue = Double(amount.replacingOccurrences(of: ",", with: ".")) else {
            errorText = "Geçersiz tutar"
            showError = true
            return
        }

        if let existing = editingTransaction {
            existing.amount = amountValue
            existing.date = date
            existing.category = selectedCategory
            existing.descriptionText = descriptionText.isEmpty ? nil : descriptionText
            existing.paymentMethod = paymentMethod.isEmpty ? nil : paymentMethod
            existing.isRecurring = isRecurring
            existing.recurrenceInterval = isRecurring ? recurrenceInterval : nil
            viewModel.updateTransaction(existing, context: modelContext)
        } else {
            viewModel.createTransaction(
                context: modelContext,
                type: type,
                category: selectedCategory,
                amount: amountValue,
                date: date,
                descriptionText: descriptionText.isEmpty ? nil : descriptionText,
                paymentMethod: paymentMethod.isEmpty ? nil : paymentMethod,
                isRecurring: isRecurring,
                recurrenceInterval: isRecurring ? recurrenceInterval : nil,
                tags: nil
            )
        }
        dismiss()
    }
}
