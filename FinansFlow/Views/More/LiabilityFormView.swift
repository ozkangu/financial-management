import SwiftUI

struct LiabilityFormView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: LiabilityViewModel

    let workspaceId: UUID
    var editingLiability: Liability?

    @State private var name = ""
    @State private var type: LiabilityType = .personalLoan
    @State private var totalAmount = ""
    @State private var remainingAmount = ""
    @State private var interestRate = ""
    @State private var monthlyPayment = ""
    @State private var dueDate = Date()
    @State private var hasDueDate = false
    @State private var notes = ""
    @State private var showError = false
    @State private var errorText = ""

    private var isEditing: Bool { editingLiability != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Borç Bilgileri") {
                    TextField("Borç Adı", text: $name)

                    Picker("Tür", selection: $type) {
                        ForEach(LiabilityType.allCases, id: \.self) { t in
                            HStack {
                                Image(systemName: t.icon)
                                Text(t.displayName)
                            }
                            .tag(t)
                        }
                    }
                }

                Section("Tutarlar") {
                    TextField("Toplam Borç", text: $totalAmount)
                        .keyboardType(.decimalPad)
                    TextField("Kalan Borç", text: $remainingAmount)
                        .keyboardType(.decimalPad)
                    TextField("Aylık Ödeme (opsiyonel)", text: $monthlyPayment)
                        .keyboardType(.decimalPad)
                    TextField("Faiz Oranı % (opsiyonel)", text: $interestRate)
                        .keyboardType(.decimalPad)
                }

                Section("Tarih") {
                    Toggle("Son Ödeme Tarihi", isOn: $hasDueDate)
                    if hasDueDate {
                        DatePicker("Tarih", selection: $dueDate, displayedComponents: .date)
                    }
                }

                Section("Not") {
                    TextField("Not (opsiyonel)", text: $notes, axis: .vertical)
                        .lineLimit(3)
                }
            }
            .navigationTitle(isEditing ? "Borç Düzenle" : "Borç Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        Task { await save() }
                    }
                    .disabled(name.isEmpty || totalAmount.isEmpty)
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
        guard let l = editingLiability else { return }
        name = l.name
        type = l.type
        totalAmount = String(l.totalAmount)
        remainingAmount = String(l.remainingAmount)
        interestRate = l.interestRate.map { String($0) } ?? ""
        monthlyPayment = l.monthlyPayment.map { String($0) } ?? ""
        if let d = l.dueDate {
            dueDate = d
            hasDueDate = true
        }
        notes = l.notes ?? ""
    }

    private func save() async {
        let total = Double(totalAmount.replacingOccurrences(of: ",", with: ".")) ?? 0
        let remaining = Double(remainingAmount.replacingOccurrences(of: ",", with: ".")) ?? 0

        do {
            if var existing = editingLiability {
                existing.name = name
                existing.type = type
                existing.totalAmount = total
                existing.remainingAmount = remaining
                existing.interestRate = Double(interestRate.replacingOccurrences(of: ",", with: "."))
                existing.monthlyPayment = Double(monthlyPayment.replacingOccurrences(of: ",", with: "."))
                existing.dueDate = hasDueDate ? dueDate : nil
                existing.notes = notes.isEmpty ? nil : notes
                try await viewModel.updateLiability(existing)
            } else {
                guard let userId = authService.currentUser?.id else { return }
                try await viewModel.createLiability(
                    workspaceId: workspaceId,
                    userId: userId,
                    name: name,
                    type: type,
                    totalAmount: total,
                    remainingAmount: remaining,
                    interestRate: Double(interestRate.replacingOccurrences(of: ",", with: ".")),
                    monthlyPayment: Double(monthlyPayment.replacingOccurrences(of: ",", with: ".")),
                    currency: AppConstants.defaultCurrency,
                    dueDate: hasDueDate ? dueDate : nil,
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
