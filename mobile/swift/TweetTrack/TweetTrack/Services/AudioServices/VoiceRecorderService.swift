import AVFoundation
import Combine
import Foundation

import os.log

let logger = Logger(subsystem: "TweetTrack.logs", category: "Audio")

final class VoiceRecorderService: ObservableObject {
    private var audioRecorder: AVAudioRecorder?
    @Published private(set) var isRecording = false
    private var elaspedTime: TimeInterval = 0
    private var startTime: Date?
    private var timer: AnyCancellable?
    
    func startRecording() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            if granted {
                print("Permission granted")
            } else {
                print("Permission denied")
            }
        }
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.overrideOutputAudioPort(.speaker)
            try audioSession.setActive(true)
            logger.info("Audio session successfully configured for recording and playback")
        } catch {
            logger.error("Error configuring audio session: \(error.localizedDescription)")
        }

        let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let audiofileName = "recording_\(Date().timeIntervalSince1970).m4a"
        let audioFileURL = documentPath.appendingPathComponent(audiofileName)
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ] as [String: Any]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFileURL, settings: settings)
            audioRecorder?.record()
            isRecording = true
            startTime = Date()
            startTimer()
            print("VoiceRecorderService: successfully setUp AVAudioSession")
        } catch {
            print("VoiceRecorderService: Failed to setUp AVAudioRecorder")
        }
    }
    
    func stopRecording(completion: ((_ audioURL: URL?, _ audioDuration: TimeInterval) -> Void)? = nil) {
        guard isRecording else { return }
        
        let audioDuration = elaspedTime
        audioRecorder?.stop()
        isRecording = false
        timer?.cancel()
        elaspedTime = 0
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setActive(false)
            guard let audioURL = audioRecorder?.url else { return }
            completion?(audioURL, audioDuration)
        } catch {
            print("VoiceRecorderService: Failed to teardown AVAudioSession")
        }
    }

    private func startTimer() {
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let startTime = self?.startTime else { return }
                self?.elaspedTime = Date().timeIntervalSince(startTime)
            }
    }
}
