import SwiftUI

struct CategoryFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: CategoryViewModel

    let workspaceId: UUID
    var editingCategory: Category?
    var categoryType: CategoryType = .expense

    @State private var name = ""
    @State private var type: CategoryType = .expense
    @State private var parentId: UUID?
    @State private var color = "#007AFF"
    @State private var icon = "folder.fill"
    @State private var monthlyBudget = ""
    @State private var showError = false
    @State private var errorText = ""

    private var isEditing: Bool { editingCategory != nil }

    private let commonIcons = [
        "folder.fill", "house.fill", "car.fill", "cart.fill",
        "heart.fill", "book.fill", "gamecontroller.fill",
        "tshirt.fill", "fork.knife", "bolt.fill", "drop.fill",
        "flame.fill", "wifi", "bus.fill", "fuelpump.fill",
        "wrench.fill", "basket.fill", "creditcard.fill",
        "briefcase.fill", "laptopcomputer", "banknote.fill",
        "chart.line.uptrend.xyaxis", "chart.pie.fill",
        "gift.fill", "tag.fill", "percent", "repeat",
        "person.fill", "ellipsis.circle.fill"
    ]

    private let colorOptions = [
        "#FF6B6B", "#4ECDC4", "#FFD93D", "#FF8C94",
        "#A8D8EA", "#C3AED6", "#FFB6B9", "#FFDAC1",
        "#B5EAD7", "#957DAD", "#95E1D3", "#2ECC71",
        "#27AE60", "#1ABC9C", "#3498DB", "#E67E22",
        "#9B59B6", "#7F8C8D", "#007AFF", "#FF9500"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Genel") {
                    TextField("Kategori Adı", text: $name)

                    if !isEditing {
                        Picker("Tür", selection: $type) {
                            Text("Gider").tag(CategoryType.expense)
                            Text("Gelir").tag(CategoryType.income)
                        }
                    }

                    let parents = viewModel.categories.filter {
                        $0.type == type && $0.parentId == nil && $0.id != editingCategory?.id
                    }
                    if !parents.isEmpty {
                        Picker("Üst Kategori", selection: $parentId) {
                            Text("Yok (Ana Kategori)").tag(UUID?.none)
                            ForEach(parents) { parent in
                                Text(parent.name).tag(UUID?.some(parent.id))
                            }
                        }
                    }
                }

                Section("Görünüm") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHGrid(rows: [GridItem(.fixed(44))], spacing: 8) {
                            ForEach(commonIcons, id: \.self) { iconName in
                                Button {
                                    icon = iconName
                                } label: {
                                    Image(systemName: iconName)
                                        .font(.title3)
                                        .frame(width: 44, height: 44)
                                        .background(icon == iconName ? Color.accentColor.opacity(0.2) : Color(.systemGray6))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .frame(height: 52)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(colorOptions, id: \.self) { colorHex in
                                Circle()
                                    .fill(Color(hex: colorHex))
                                    .frame(width: 32, height: 32)
                                    .overlay {
                                        if color == colorHex {
                                            Image(systemName: "checkmark")
                                                .font(.caption.bold())
                                                .foregroundStyle(.white)
                                        }
                                    }
                                    .onTapGesture { color = colorHex }
                            }
                        }
                    }
                }

                Section("Bütçe") {
                    TextField("Aylık Bütçe (opsiyonel)", text: $monthlyBudget)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle(isEditing ? "Kategori Düzenle" : "Yeni Kategori")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        Task { await save() }
                    }
                    .disabled(name.isEmpty)
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
        guard let cat = editingCategory else {
            type = categoryType
            return
        }
        name = cat.name
        type = cat.type
        parentId = cat.parentId
        color = cat.color
        icon = cat.icon
        monthlyBudget = cat.monthlyBudget.map { String($0) } ?? ""
    }

    private func save() async {
        let budget = Double(monthlyBudget)

        do {
            if var existing = editingCategory {
                existing.name = name
                existing.parentId = parentId
                existing.color = color
                existing.icon = icon
                existing.monthlyBudget = budget
                try await viewModel.updateCategory(existing)
            } else {
                try await viewModel.createCategory(
                    workspaceId: workspaceId,
                    name: name,
                    type: type,
                    parentId: parentId,
                    color: color,
                    icon: icon,
                    monthlyBudget: budget
                )
            }
            dismiss()
        } catch {
            errorText = error.localizedDescription
            showError = true
        }
    }
}
