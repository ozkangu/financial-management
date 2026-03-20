import SwiftUI

struct SignUpView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showError = false
    @State private var errorText = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.accentColor)
                        Text("FinansFlow")
                            .font(.largeTitle.bold())
                        Text("Hesap Oluştur")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 32)

                    VStack(spacing: 16) {
                        TextField("Ad Soyad", text: $name)
                            .textContentType(.name)
                            .autocorrectionDisabled()

                        TextField("E-posta", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                        SecureField("Şifre", text: $password)
                            .textContentType(.newPassword)

                        SecureField("Şifre Tekrar", text: $confirmPassword)
                            .textContentType(.newPassword)
                    }
                    .textFieldStyle(.roundedBorder)

                    Button {
                        Task { await signUp() }
                    } label: {
                        if authService.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Kayıt Ol")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(!isFormValid || authService.isLoading)
                }
                .padding(.horizontal, 24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .alert("Hata", isPresented: $showError) {
                Button("Tamam") {}
            } message: {
                Text(errorText)
            }
        }
    }

    private var isFormValid: Bool {
        !name.isEmpty && !email.isEmpty && !password.isEmpty
        && password == confirmPassword && password.count >= 6
    }

    private func signUp() async {
        do {
            try await authService.signUp(email: email, password: password, name: name)
        } catch {
            errorText = error.localizedDescription
            showError = true
        }
    }
}

#Preview {
    SignUpView()
        .environment(AuthService())
}
