import SwiftUI

struct ContentView: View {
    @StateObject private var authService = AuthService()
    
    var body: some View {
        BottomNavigationView()
            .environmentObject(authService)
    }
}

#Preview {
    ContentView()
}
