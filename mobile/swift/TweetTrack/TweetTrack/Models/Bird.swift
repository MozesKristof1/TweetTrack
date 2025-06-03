import Foundation

struct Bird: Codable, Identifiable {
    var id: UUID
    var ebird_id: String?
    let name: String
    let scientific_name: String?
    let description: String?
    let base_image_url: String?
    let base_sound_url: String?
}
