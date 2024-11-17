import Foundation
import SwiftData

@Model
final class BirdSoundItem: Identifiable {
    var id: UUID
    var title: String
    var audioDataPath: String
    var duration: Double
    var dateCreated: Date

    init(title: String, audioDataPath: String, duration: Double, dateCreated: Date = Date()) {
        self.id = UUID() 
        self.title = title
        self.audioDataPath = audioDataPath
        self.duration = duration
        self.dateCreated = dateCreated
    }
}
