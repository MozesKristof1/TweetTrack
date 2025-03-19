import Foundation
import AVFAudio

final class AudioPlayerService: ObservableObject {
    private var audioPlayer: AVAudioPlayer?

    func playAudio(at url: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            print("AudioPlayerService: Failed to play audio with error: \(error.localizedDescription)")
        }
    }
    
    func stopAudio() {
          audioPlayer?.stop()
    }

}
