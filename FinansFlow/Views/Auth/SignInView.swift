import SwiftUI

struct SignInView: View {
    @Environment(AuthService.self) private var authService

    @State private var email = ""
    @State private var password = ""
    @State private var showSignUp = false
    @State private var showError = false
    @State private var errorText = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(Color.accentColor)
                        Text("FinansFlow")
                            .font(.largeTitle.bold())
                        Text("Finansal hayatını kontrol altına al")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 60)

                    VStack(spacing: 16) {
                        TextField("E-posta", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                        SecureField("Şifre", text: $password)
                            .textContentType(.password)
                    }
                    .textFieldStyle(.roundedBorder)

                    Button {
                        Task { await signIn() }
                    } label: {
                        if authService.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Giriş Yap")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(!isFormValid || authService.isLoading)

                    SignInWithAppleButton()

                    Divider()

                    Button("Hesabın yok mu? Kayıt Ol") {
                        showSignUp = true
                    }
                    .font(.subheadline)
                }
                .padding(.horizontal, 24)
            }
            .sheet(isPresented: $showSignUp) {
                SignUpView()
                    .environment(authService)
            }
            .alert("Hata", isPresented: $showError) {
                Button("Tamam") {}
            } message: {
                Text(errorText)
            }
        }
    }

    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty
    }

    private func signIn() async {
        do {
            try await authService.signIn(email: email, password: password)
        } catch {
            errorText = error.localizedDescription
            showError = true
        }
    }
}

#Preview {
    SignInView()
        .environment(AuthService())
}
