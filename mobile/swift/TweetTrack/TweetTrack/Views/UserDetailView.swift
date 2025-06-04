import SwiftUI

struct UserDetailView: View {
    @EnvironmentObject var authService: AuthService
    @State private var showingAuthSheet = false
    
    var body: some View {
        VStack(spacing: 20) {
            if authService.isLoggedIn {
                // Logged in state
                VStack(spacing: 15) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("Welcome, \(authService.currentUser)!")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("You are logged in")
                        .foregroundColor(.secondary)
                    
                    // Logged-in user features
                    VStack(spacing: 10) {
                        NavigationLink("My Saved Birds") {
                            Text("Saved Birds View")
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(10)
                        
                        NavigationLink("Settings") {
                            Text("Settings View")
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(10)
                    }
                    
                    Spacer()
                    
                    Button("Logout") {
                        authService.logout()
                    }
                    .foregroundColor(.red)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(10)
                }
            } else {
                VStack(spacing: 15) {
                    Image(systemName: "person.circle")
                        .font(.system(size: 80))
                        .foregroundColor(.gray)
                    
                    Text("Profile")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Login to share your observations and become part of the community!")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    Button("Login / Register") {
                        showingAuthSheet = true
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
        }
        .padding()
        .navigationTitle("Profile")
        .sheet(isPresented: $showingAuthSheet) {
            AuthView()
                .environmentObject(authService)
        }
    }
}

#Preview {
    UserDetailView()
}
