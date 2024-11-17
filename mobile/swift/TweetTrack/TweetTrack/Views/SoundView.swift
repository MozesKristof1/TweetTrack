import SwiftUI
import AVFoundation
import SwiftData

struct SoundView: View {
    @StateObject private var voiceRecorder = VoiceRecorderService()
    @StateObject private var audioPlayer = AudioPlayerService()
    
    @State private var recordingURL: URL?
    @State private var recordingDuration: TimeInterval = 0
    
    @Environment(\.modelContext) private var context
    @Query private var birdSounds: [BirdSoundItem]

    var body: some View {
        VStack(spacing: 20) {
            Button(action: {
                if voiceRecorder.isRecording {
                    stopRecording()
                } else {
                    startRecording()
                }
            }) {
                Text(voiceRecorder.isRecording ? "Stop Recording" : "Start Recording")
                    .padding()
                    .background(voiceRecorder.isRecording ? Color.red : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }

            if let recordingURL = recordingURL {
                Text("Recording saved at: \(recordingURL.lastPathComponent)")
                Text("Duration: \(String(format: "%.1f", recordingDuration)) seconds")
                
                Button(action: {
                    playRecording()
                }) {
                    Text("Play Recording")
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            List{
                ForEach(birdSounds) { sound in
                    Text(sound.title)}
            }
        }
        .padding()
    }

    private func startRecording() {
        voiceRecorder.startRecording()
    }

    private func stopRecording() {
        voiceRecorder.stopRecording { url, duration in
            self.recordingURL = url
            self.recordingDuration = duration
            
            if let url = url {
                      let newBirdSoundItem = BirdSoundItem(
                          title: "Bird Recording \(Date())",
                          audioDataPath: url.path,
                          duration: duration
                      )
                      context.insert(newBirdSoundItem)
                  }
        }
    }

    private func playRecording() {
        if let url = recordingURL {
            audioPlayer.playAudio(at: url)
        }
    }
}

#Preview {
    SoundView()
}
