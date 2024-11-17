import Foundation
import SwiftData

@Model
class BirdSoundItem: Identifiable {
    var id = UUID()
    var title: String
    var audioDataPath: String
    var duration: Double
    var dareCreated: Date

    init(id: UUID = UUID(), title: String, audioDataPath: String, duration: Double, dareCreated: Date = Date()) {
        self.id = id
        self.title = title
        self.audioDataPath = audioDataPath
        self.duration = duration
        self.dareCreated = dareCreated
    }

    var audioDataUrl: URL {
        URL(fileURLWithPath: audioDataPath)
    }
}
