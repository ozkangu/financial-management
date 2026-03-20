import SwiftUI

struct WorkspaceSwitcher: View {
    @Bindable var viewModel: WorkspaceViewModel

    var body: some View {
        Menu {
            ForEach(viewModel.workspaces) { ws in
                Button {
                    viewModel.activeWorkspace = ws
                } label: {
                    HStack {
                        Text(ws.name)
                        if ws.id == viewModel.activeWorkspace?.id {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(viewModel.activeWorkspace?.name ?? String(localized: "Workspace"))
                    .font(.headline)
                Image(systemName: "chevron.down")
                    .font(.caption)
            }
        }
    }
}
