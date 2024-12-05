import Foundation

struct BirdLocation : Codable, Identifiable {
    var id = UUID()
    var birdId = UUID()
    let latitude: Float
    let longitude: Float
}
