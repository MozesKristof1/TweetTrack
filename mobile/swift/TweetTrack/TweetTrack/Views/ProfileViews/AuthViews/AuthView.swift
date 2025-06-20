import SwiftUI
import Foundation


struct AuthView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    @State private var isShowingLogin = true
    
    var body: some View {
        NavigationView {
            VStack {
                if isShowingLogin {
                    LoginView()
                } else {
                    RegisterView()
                }
                
                Button(action: {
                    isShowingLogin.toggle()
                }) {
                    Text(isShowingLogin ? "Don't have an account? Register" : "Already have an account? Login")
                        .foregroundColor(.blue)
                        .padding()
                }
            }
            .navigationTitle(isShowingLogin ? "Login" : "Register")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onChange(of: authService.isLoggedIn) { isLoggedIn in
            if isLoggedIn {
                dismiss()
            }
        }
    }
}


#Preview {
    ContentView()
}
