import SwiftUI
import LocalAuthentication

struct BiometricLockView: View {
    @State private var isUnlocked = false
    @State private var showError = false

    var onUnlock: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: biometricType == .faceID ? "faceid" : "touchid")
                .font(.system(size: 64))
                .foregroundStyle(Color.accentColor)

            Text("Kilit Açma")
                .font(.title2.bold())

            Text("Devam etmek için kimlik doğrulama yapın")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button("Kilidi Aç") {
                authenticate()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Spacer()
        }
        .onAppear {
            authenticate()
        }
        .alert("Kimlik Doğrulama Başarısız", isPresented: $showError) {
            Button("Tekrar Dene") { authenticate() }
            Button("İptal", role: .cancel) {}
        }
    }

    private var biometricType: LABiometryType {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        return context.biometryType
    }

    private func authenticate() {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            onUnlock()
            return
        }

        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Uygulamaya erişmek için kimlik doğrulayın") { success, _ in
            DispatchQueue.main.async {
                if success {
                    onUnlock()
                } else {
                    showError = true
                }
            }
        }
    }
}
