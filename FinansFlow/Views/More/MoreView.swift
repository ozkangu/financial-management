import SwiftUI

struct MoreView: View {
    @Bindable var categoryVM: CategoryViewModel
    @Bindable var transactionVM: TransactionViewModel
    @Bindable var investmentVM: InvestmentViewModel
    @Bindable var passiveIncomeVM: PassiveIncomeViewModel
    @Bindable var liabilityVM: LiabilityViewModel

    init(
        categoryVM: CategoryViewModel = CategoryViewModel(),
        transactionVM: TransactionViewModel = TransactionViewModel(),
        investmentVM: InvestmentViewModel = InvestmentViewModel(),
        passiveIncomeVM: PassiveIncomeViewModel = PassiveIncomeViewModel(),
        liabilityVM: LiabilityViewModel = LiabilityViewModel()
    ) {
        self.categoryVM = categoryVM
        self.transactionVM = transactionVM
        self.investmentVM = investmentVM
        self.passiveIncomeVM = passiveIncomeVM
        self.liabilityVM = liabilityVM
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Finans") {
                    NavigationLink {
                        CategoryListView(
                            viewModel: categoryVM,
                            transactionVM: transactionVM
                        )
                    } label: {
                        Label("Kategoriler", systemImage: "folder.fill")
                    }

                    NavigationLink {
                        PassiveIncomeListView(
                            viewModel: passiveIncomeVM,
                            investmentVM: investmentVM
                        )
                    } label: {
                        Label("Pasif Gelirler", systemImage: "leaf.fill")
                    }

                    NavigationLink {
                        LiabilityListView(viewModel: liabilityVM)
                    } label: {
                        Label("Borçlar", systemImage: "creditcard.fill")
                    }
                }

                Section("Uygulama") {
                    NavigationLink {
                        SettingsView(
                            transactionVM: transactionVM,
                            categoryVM: categoryVM
                        )
                    } label: {
                        Label("Ayarlar", systemImage: "gearshape.fill")
                    }
                }
            }
            .navigationTitle("Daha Fazla")
        }
    }
}

#Preview {
    MoreView()
}
