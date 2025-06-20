import Foundation

struct UserImageData: Codable {
    let image_id: String
    let observation_id: String
    let base64_image: String
    let caption: String?
    let observed_at: String
    let latitude: Double?
    let longitude: Double?
    let notes: String?
}
