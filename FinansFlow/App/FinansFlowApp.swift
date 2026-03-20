import SwiftUI

@main
struct FinansFlowApp: App {
    @State private var authService = AuthService()
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("biometricLockEnabled") private var biometricLockEnabled = false
    @State private var isUnlocked = false

    var body: some Scene {
        WindowGroup {
            Group {
                if !hasSeenOnboarding {
                    OnboardingView()
                } else if biometricLockEnabled && !isUnlocked {
                    BiometricLockView {
                        isUnlocked = true
                    }
                } else if authService.isAuthenticated {
                    ContentView()
                } else {
                    SignInView()
                }
            }
            .environment(authService)
        }
    }
}
