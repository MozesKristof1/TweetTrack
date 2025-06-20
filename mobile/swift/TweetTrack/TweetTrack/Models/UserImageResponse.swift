import Foundation

struct UserImageResponse: Codable {
    let ebird_id: String
    let total_observations: Int
    let total_images: Int
    let images: [UserImageData]
}
