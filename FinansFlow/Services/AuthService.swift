import Foundation
import Supabase
import AuthenticationServices

@Observable
final class AuthService {
    var isAuthenticated = false
    var currentUser: AppUser?
    var isLoading = false
    var errorMessage: String?

    private var client: SupabaseClient {
        SupabaseConfig.client
    }

    init() {
        Task {
            await checkSession()
        }
    }

    func checkSession() async {
        do {
            let session = try await client.auth.session
            isAuthenticated = true
            await fetchUserProfile(userId: session.user.id)
        } catch {
            isAuthenticated = false
            currentUser = nil
        }
    }

    func signUp(email: String, password: String, name: String) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response = try await client.auth.signUp(
                email: email,
                password: password,
                data: ["name": .string(name)]
            )
            isAuthenticated = true
            await fetchUserProfile(userId: response.user.id)
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }

    func signIn(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let session = try await client.auth.signIn(
                email: email,
                password: password
            )
            isAuthenticated = true
            await fetchUserProfile(userId: session.user.id)
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }

    func signInWithApple(idToken: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let session = try await client.auth.signInWithIdToken(
                credentials: .init(provider: .apple, idToken: idToken)
            )
            isAuthenticated = true
            await fetchUserProfile(userId: session.user.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signOut() async {
        do {
            try await client.auth.signOut()
        } catch {
            // Ignore sign out errors
        }
        isAuthenticated = false
        currentUser = nil
    }

    private func fetchUserProfile(userId: UUID) async {
        do {
            let user: AppUser = try await SupabaseService.shared.fetchOne(
                from: "users",
                id: userId
            )
            currentUser = user
        } catch {
            // Profile may not exist yet
        }
    }
}
