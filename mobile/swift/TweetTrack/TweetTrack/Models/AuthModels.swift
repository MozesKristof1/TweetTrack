import Foundation

struct UserRegistration: Codable {
    let username: String
    let email: String
    let password: String
}

struct UserLogin: Codable {
    let username: String
    let password: String
}

struct TokenResponse: Codable {
    let access_token: String
    let token_type: String
}

struct RegisterResponse: Codable {
    let message: String
}

struct ErrorResponse: Codable {
    let detail: String
}
