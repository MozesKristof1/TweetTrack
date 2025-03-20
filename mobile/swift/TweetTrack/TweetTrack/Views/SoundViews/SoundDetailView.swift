import SwiftUI

struct SoundDetailView: View {
    let sound: BirdSoundItem
    let detectionService: BirdDetectionService
    var body: some View {
        Text(sound.title)
        Text(detectionService.detectBirdSound(audioURL: URL(fileURLWithPath: sound.audioDataPath)))
    }
}
