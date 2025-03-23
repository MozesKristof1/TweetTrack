import SwiftUI

struct SoundDetailView: View {
    let sound: BirdSoundItem
    let detectionService: BirdDetectionService
    let postService: AudioUploadService
    private let detectionResult: String

    init(sound: BirdSoundItem, detectionService: BirdDetectionService, postService: AudioUploadService) {
        self.sound = sound
        self.detectionService = detectionService
        self.postService = postService
        self.detectionResult = detectionService.detectBirdSound(audioURL: URL(fileURLWithPath: sound.audioDataPath)).0
        if detectionResult == "Bird detected" {
            sound.detectedBird = true
        }
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
                let fileURL = URL(fileURLWithPath: sound.audioDataPath)
                postService.uploadSoundFile(fileURL: fileURL) { result in
                    switch result {
                    case .success(let data):
                        print("Upload successful! Response: \(String(decoding: data, as: UTF8.self))")
                    case .failure(let error):
                        print("Upload failed: \(error.localizedDescription)")
                    }
                }
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
