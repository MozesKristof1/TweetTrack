import Foundation

struct BirdLocation : Codable, Identifiable {
    let id = UUID()
    let birdId = UUID()
    let latitude: Float
    let longitude: Float
}
