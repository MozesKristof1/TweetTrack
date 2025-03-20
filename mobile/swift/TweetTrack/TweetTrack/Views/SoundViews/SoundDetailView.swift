import SwiftUI

struct SoundDetailView: View {
    let sound: BirdSoundItem
    let detectionService: BirdDetectionService
    private let detectionResult: String

    init(sound: BirdSoundItem, detectionService: BirdDetectionService) {
        self.sound = sound
        self.detectionService = detectionService
        self.detectionResult = detectionService.detectBirdSound(audioURL: URL(fileURLWithPath: sound.audioDataPath))
    }

    var body: some View {
        VStack(spacing: 20) {
            Text(sound.title)
                .font(.title)
                .fontWeight(.bold)
                .padding()

            Text(detectionResult)
                .font(.headline)
                .foregroundColor(.gray)
                .padding()

            Button(action: {
                // Call post requesr for identification
            }) {
                Text("Identify the Bird")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 20)
        }
        .padding()
    }
}
