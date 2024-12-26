import AVFoundation
import SwiftData
import SwiftUI

struct SoundListView: View {
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

            ScrollView {
                ForEach(birdSounds) { sound in
                    NavigationLink(destination: SoundDetailView(sound: sound)) {
                        SoundCardView(
                            sound: sound,
                            onDelete: {
                                context.delete(sound)
                            },
                            onPlay: {
                                playRecordingAtUrl(url: URL(fileURLWithPath: sound.audioDataPath))
                            },
                            onStop: {
                                audioPlayer.stopAudio()
                            }
                        )
                    }
                    .contentShape(Rectangle())
                    .padding(.vertical, 4)
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
    SoundListView()
}
