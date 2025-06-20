import Foundation
import SwiftData

@Model
final class BirdSoundItem: Identifiable {
    var id: UUID
    var title: String
    var audioDataPath: String
    var duration: Double
    var dateCreated: Date
    var detectedBird: Bool = false
    
    // Properties for identified bird
    var birdName: String?
    var scientificName: String?
    var birdDescription: String?
    var imageUrl: String?
    var confidence: Double?
    
    // Taxonomy
    var genus: String?
    var family: String?
    var order: String?
    
    init(title: String, audioDataPath: String, duration: Double, dateCreated: Date = Date()) {
        self.id = UUID()
        self.title = title
        self.audioDataPath = audioDataPath
        self.duration = duration
        self.dateCreated = dateCreated
    }
    
    func updateBirdIdentification(
        name: String,
        scientificName: String,
        identificationText: String,
        imageUrl: String,
        probability: Double,
        genus: String? = nil,
        family: String? = nil,
        order: String? = nil
    ) {
        self.detectedBird = true
        self.birdName = name
        self.scientificName = scientificName
        self.birdDescription = identificationText
        self.imageUrl = imageUrl
        self.confidence = probability
        self.genus = genus
        self.family = family
        self.order = order
    }
}
