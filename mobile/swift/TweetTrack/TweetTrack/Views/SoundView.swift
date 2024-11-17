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
            List {
                ForEach(birdSounds) { sound in
                    HStack {
                        Button(action: {
                            context.delete(sound)
                        }) {
                            Image(systemName: "trash")
                                .padding()
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Text(sound.title)
                            .padding()
                        
                        Spacer()
                        
                        Button(action: {
                            playRecordingAtUrl(url: URL(fileURLWithPath: sound.audioDataPath))
                        }) {
                            Image(systemName: "speaker.wave.2.circle")
                                .padding()
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
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

    private func playRecordingAtUrl(url: URL) {
        audioPlayer.playAudio(at: url)
    }
}

#Preview {
    SoundView()
}
