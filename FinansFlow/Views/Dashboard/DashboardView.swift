import SwiftUI

struct DashboardView: View {
    @Bindable var transactionVM: TransactionViewModel
    @Bindable var categoryVM: CategoryViewModel
    @Bindable var workspaceVM: WorkspaceViewModel

    init(transactionVM: TransactionViewModel = TransactionViewModel(),
         categoryVM: CategoryViewModel = CategoryViewModel(),
         workspaceVM: WorkspaceViewModel = WorkspaceViewModel()) {
        self.transactionVM = transactionVM
        self.categoryVM = categoryVM
        self.workspaceVM = workspaceVM
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Text("Dashboard içeriği buraya gelecek")
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    WorkspaceSwitcher(viewModel: workspaceVM)
                }
            }
        }
    }
}

#Preview {
    DashboardView()
}
