import SwiftUI
import Foundation

class AuthService: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var isLoggedIn = false
    @Published var accessToken: String? = nil 
    @Published var currentUser: String = ""
    
    init() {
        checkExistingToken()
    }
    
    func register(username: String, email: String, password: String) async {
        await MainActor.run {
            isLoading = true
            errorMessage = ""
        }
        
        
        guard let url = URL(string: Api.register) else {
            await MainActor.run {
                errorMessage = "Invalid URL"
                isLoading = false
            }
            return
        }
        
        let userData = UserRegistration(username: username, email: email, password: password)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONEncoder().encode(userData)
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    await MainActor.run {
                        errorMessage = "Registration successful! Please log in."
                        isLoading = false
                    }
                } else {
                    let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
                    await MainActor.run {
                        errorMessage = errorResponse.detail
                        isLoading = false
                    }
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Registration failed: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    func login(username: String, password: String) async {
        await MainActor.run {
            isLoading = true
            errorMessage = ""
        }
        
        guard let url = URL(string: Api.login) else {
            await MainActor.run {
                errorMessage = "Invalid URL"
                isLoading = false
            }
            return
        }
        
        let userData = UserLogin(username: username, password: password)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONEncoder().encode(userData)
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
                    await MainActor.run {
                        accessToken = tokenResponse.access_token
                        currentUser = username
                        isLoggedIn = true
                        isLoading = false
                        UserDefaults.standard.set(tokenResponse.access_token, forKey: "access_token")
                        UserDefaults.standard.set(username, forKey: "current_user")
                    }
                } else {
                    let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
                    await MainActor.run {
                        errorMessage = errorResponse.detail
                        isLoading = false
                    }
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Login failed: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    func logout() {
        isLoggedIn = false
        accessToken = ""
        currentUser = ""
        UserDefaults.standard.removeObject(forKey: "access_token")
        UserDefaults.standard.removeObject(forKey: "current_user")
    }
    
    func checkExistingToken() {
        if let token = UserDefaults.standard.string(forKey: "access_token"), !token.isEmpty,
           let user = UserDefaults.standard.string(forKey: "current_user") {
            accessToken = token
            currentUser = user
            isLoggedIn = true
        }
    }
}
