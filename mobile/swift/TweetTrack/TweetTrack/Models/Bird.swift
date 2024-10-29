import Foundation

struct Bird : Codable, Identifiable {
    let id = UUID()
    let name: String
    let base64Picture: String
    let description: String
}

