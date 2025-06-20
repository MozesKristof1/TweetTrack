import Foundation

struct BirdObservationCreate: Codable {
    let ebird_id: String
    let latitude: Double
    let longitude: Double
    let observed_at: Date
    let notes: String?
}

struct BirdObservationResponse: Codable, Equatable, Identifiable {
    let id: UUID
    let user_id: UUID
    let ebird_id: String
    let latitude: Double
    let longitude: Double
    let observed_at: Date
    let notes: String?
    let bird_name: String?
    let bird_scientific_name: String?
}
