import SwiftUI

struct ContentView: View {
    @StateObject private var authService = AuthService()
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding: Bool = false

    
    var body: some View {
        if hasSeenOnboarding {
            BottomNavigationView()
                .environmentObject(authService)
        }
        else {
            OnboardingView()
        }
    }
}

#Preview {
    ContentView()
}
