import SwiftUI
import SwiftData

@main
struct FinansFlowApp: App {
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
                } else {
                    ContentView()
                }
            }
        }
        .modelContainer(for: [
            Category.self,
            Transaction.self,
            Investment.self,
            PassiveIncome.self,
            Asset.self,
            Liability.self,
            NetWorthSnapshot.self
        ])
    }
}
