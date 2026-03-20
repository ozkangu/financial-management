import SwiftUI

struct LoadingView: View {
    var message: String = "Yükleniyor..."

    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.2)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ErrorBanner: View {
    let message: String
    var retryAction: (() -> Void)?

    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
            Text(message)
                .font(.subheadline)
                .lineLimit(2)
            Spacer()
            if let retryAction {
                Button("Tekrar Dene", action: retryAction)
                    .font(.subheadline.bold())
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal)
    }
}

#Preview {
    VStack {
        LoadingView()
        ErrorBanner(message: "Bağlantı hatası") {}
    }
}
