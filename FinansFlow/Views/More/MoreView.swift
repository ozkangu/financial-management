import SwiftUI

struct MoreView: View {
    @Environment(AuthService.self) private var authService
    @Bindable var workspaceVM: WorkspaceViewModel
    @Bindable var categoryVM: CategoryViewModel
    @Bindable var transactionVM: TransactionViewModel
    @Bindable var investmentVM: InvestmentViewModel
    @Bindable var passiveIncomeVM: PassiveIncomeViewModel
    @Bindable var liabilityVM: LiabilityViewModel

    init(workspaceVM: WorkspaceViewModel = WorkspaceViewModel(),
         categoryVM: CategoryViewModel = CategoryViewModel(),
         transactionVM: TransactionViewModel = TransactionViewModel(),
         investmentVM: InvestmentViewModel = InvestmentViewModel(),
         passiveIncomeVM: PassiveIncomeViewModel = PassiveIncomeViewModel(),
         liabilityVM: LiabilityViewModel = LiabilityViewModel()) {
        self.workspaceVM = workspaceVM
        self.categoryVM = categoryVM
        self.transactionVM = transactionVM
        self.investmentVM = investmentVM
        self.passiveIncomeVM = passiveIncomeVM
        self.liabilityVM = liabilityVM
    }

    private var wsId: UUID {
        workspaceVM.activeWorkspace?.id ?? UUID()
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Finans") {
                    NavigationLink {
                        CategoryListView(
                            viewModel: categoryVM,
                            transactionVM: transactionVM,
                            workspaceId: wsId
                        )
                    } label: {
                        Label("Kategoriler", systemImage: "folder.fill")
                    }

                    NavigationLink {
                        PassiveIncomeListView(
                            viewModel: passiveIncomeVM,
                            investmentVM: investmentVM,
                            workspaceId: wsId
                        )
                    } label: {
                        Label("Pasif Gelirler", systemImage: "chart.bar.fill")
                    }

                    NavigationLink {
                        LiabilityListView(viewModel: liabilityVM, workspaceId: wsId)
                    } label: {
                        Label("Borçlar", systemImage: "creditcard.fill")
                    }
                }

                Section("Workspace") {
                    NavigationLink {
                        WorkspaceListView(viewModel: workspaceVM)
                    } label: {
                        Label("Workspace'ler", systemImage: "person.2.fill")
                    }

                    NavigationLink {
                        MemberListView(viewModel: workspaceVM)
                    } label: {
                        Label("Üyeler", systemImage: "person.badge.plus")
                    }
                }

                Section("Uygulama") {
                    NavigationLink {
                        SettingsView(
                            workspace: workspaceVM.activeWorkspace,
                            transactionVM: transactionVM,
                            categoryVM: categoryVM
                        )
                    } label: {
                        Label("Ayarlar", systemImage: "gearshape.fill")
                    }

                    Button(role: .destructive) {
                        Task { await authService.signOut() }
                    } label: {
                        Label("Çıkış Yap", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Daha Fazla")
        }
    }
}

#Preview {
    MoreView()
        .environment(AuthService())
}
