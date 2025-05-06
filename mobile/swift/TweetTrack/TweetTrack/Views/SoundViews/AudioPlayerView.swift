import AVFAudio
import AVFoundation
import SwiftUI

struct AudioWaveformView: View {
    let audioURL: URL
    @State private var waveformData: [Float] = []
    @State private var player: AVAudioPlayer?
    @State private var isPlaying: Bool = false
    @State private var currentTime: TimeInterval = 0
    @State private var duration: TimeInterval = 0
    @State private var playbackPosition: CGFloat = 0
    @State private var timer: Timer?
    
    @State private var selectionStart: CGFloat? = nil
    @State private var selectionEnd: CGFloat? = nil
    @State private var isSelectingMode: Bool = false
    @State private var showCutConfirmation: Bool = false
    
    private let waveAmplification: Float = 1.5
    
    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Soundwave bars
                    HStack(alignment: .center, spacing: 1) {
                        ForEach(0..<waveformData.count, id: \.self) { i in
                            Rectangle()
                                .fill(
                                    getBarColor(index: i, geometry: geometry)
                                )
                                .frame(
                                    width: max(1, geometry.size.width / CGFloat(waveformData.count) - 1),
                                    height: CGFloat(min(1.0, abs(waveformData[i]) * waveAmplification)) * geometry.size.height * 0.85
                                )
                        }
                    }
                    .frame(height: geometry.size.height * 0.85)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    
                    // Selection area overlay
                    if let start = selectionStart, let end = selectionEnd {
                        Rectangle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(
                                width: abs(end - start) * geometry.size.width,
                                height: geometry.size.height * 0.85
                            )
                            .position(
                                x: (min(start, end) + abs(end - start) / 2) * geometry.size.width,
                                y: geometry.size.height / 2
                            )
                            .onAppear {
                                playbackPosition = min(start, end)
                                
                                // set up audio player to start from cutting
                                if let player = player, duration > 0 {
                                               let seekTime = duration * TimeInterval(min(start, end))
                                               player.currentTime = seekTime
                                               currentTime = seekTime
                                           }
                            }
                    }
                    
                    if let start = selectionStart, isSelectingMode {
                        Rectangle()
                            .fill(Color.green)
                            .frame(width: 2, height: geometry.size.height * 0.85)
                            .position(x: start * geometry.size.width, y: geometry.size.height / 2)
                            .opacity(0.8)
                    }
                    
                    if let end = selectionEnd, isSelectingMode {
                        Rectangle()
                            .fill(Color.green)
                            .frame(width: 2, height: geometry.size.height * 0.85)
                            .position(x: end * geometry.size.width, y: geometry.size.height / 2)
                            .opacity(0.8)
                    }
                    
                    // Playback positinon
                    Rectangle()
                        .fill(Color.red)
                        .frame(width: 2, height: geometry.size.height * 0.85)
                        .position(x: playbackPosition * geometry.size.width, y: geometry.size.height / 2)
                        .opacity(0.8)
                        .animation(.linear(duration: 0.1), value: playbackPosition)
                        .shadow(color: .red.opacity(0.5), radius: 2, x: 0, y: 0)
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            if isSelectingMode {
                                let percentage = value.location.x / geometry.size.width
                                if selectionStart == nil {
                                    selectionStart = max(0, min(1, percentage))
                                }
                                selectionEnd = max(0, min(1, percentage))
                            }
                        }
                        .onEnded { value in
                            if !isSelectingMode {
                                let percentage = value.location.x / geometry.size.width
                                seekTo(percentage: percentage)
                            }
                        }
                )
            }
            
            HStack {
                Text(formatTime(currentTime))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
                
                Spacer()
                
                Button(action: togglePlayback) {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 34, height: 34)
                        .foregroundColor(.blue)
                        .shadow(color: .blue.opacity(0.3), radius: 3, x: 0, y: 0)
                }
                
                // cut button
                if isSelectingMode {
                    Button(action: {
                        selectionStart = nil
                        selectionEnd = nil
                        isSelectingMode = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 34, height: 34)
                            .foregroundColor(.red)
                    }
                    
                    Button(action: {
                        if selectionStart != nil, selectionEnd != nil {
                            showCutConfirmation = true
                        }
                    }) {
                        Image(systemName: "scissors")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 34, height: 34)
                            .foregroundColor(.green)
                            .opacity((selectionStart != nil && selectionEnd != nil) ? 1.0 : 0.5)
                    }
                    .disabled(selectionStart == nil || selectionEnd == nil)
                } else {
                    Button(action: {
                        isSelectingMode = true
                        pausePlayback()
                    }) {
                        Image(systemName: "scissors.badge.ellipsis")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 34, height: 34)
                            .foregroundColor(.orange)
                    }
                }
                
                Spacer()
                
                // Duration label
                Text(formatTime(duration))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }
            .padding(.horizontal, 8)
        }
        .onAppear {
            setupAudio()
        }
        .onDisappear {
            stopPlayback()
        }
        .alert(isPresented: $showCutConfirmation) {
            Alert(
                title: Text("Cut Audio"),
                message: Text("Do you want to cut this audio?"),
                primaryButton: .destructive(Text("Cut")) {
                    cutSelectedAudio()
                },
                secondaryButton: .cancel {
                    showCutConfirmation = false
                }
            )
        }
    }
    
    private func getBarColor(index: Int, geometry: GeometryProxy) -> Color {
        let barPosition = CGFloat(index) / CGFloat(waveformData.count)
        
        if isSelectingMode,
           let start = selectionStart,
           let end = selectionEnd,
           barPosition >= min(start, end),
           barPosition <= max(start, end)
        {
            return Color.green.opacity(0.7)
        }
        
        if barPosition <= playbackPosition {
            return Color.blue
        } else {
            return Color.blue.opacity(0.4)
        }
    }
    
    private func setupAudio() {
        loadWaveformData()
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            
            player = try AVAudioPlayer(contentsOf: audioURL)
            player?.prepareToPlay()
            duration = player?.duration ?? 0
        } catch {
            print("Error setting up audio player: \(error)")
        }
    }
    
    private func togglePlayback() {
        if isPlaying {
            pausePlayback()
        } else {
            startPlayback()
        }
    }
    
    private func startPlayback() {
        guard let player = player else { return }
        
        player.play()
        isPlaying = true
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
            if let player = self.player {
                self.currentTime = player.currentTime
                
                withAnimation(.linear(duration: 0.01)) {
                    self.playbackPosition = min(1.0, CGFloat(self.currentTime / self.duration))
                }
                
                if !player.isPlaying && self.isPlaying {
                    self.stopPlayback()
                }
            }
        }
    }
    
    private func pausePlayback() {
        player?.pause()
        isPlaying = false
        timer?.invalidate()
        timer = nil
    }
    
    private func stopPlayback() {
        player?.stop()
        player?.currentTime = 0
        isPlaying = false
        currentTime = 0
        
        withAnimation(.easeOut(duration: 0.3)) {
            playbackPosition = 0
        }
        
        timer?.invalidate()
        timer = nil
    }
    
    private func seekTo(percentage: CGFloat) {
        guard let player = player, duration > 0 else { return }
        
        let clampedPercentage = max(0, min(1, percentage))
        let seekTime = duration * TimeInterval(clampedPercentage)
        
        player.currentTime = seekTime
        currentTime = seekTime
        
        withAnimation(.easeOut(duration: 0.2)) {
            playbackPosition = clampedPercentage
        }
        
        if isPlaying {
            player.play()
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    func loadWaveformData() {
        guard let audioFile = try? AVAudioFile(forReading: audioURL) else {
            print("Error loading audio file")
            return
        }

        let audioFormat = audioFile.processingFormat
        let audioFrameCount = audioFile.length
        let audioBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: AVAudioFrameCount(audioFrameCount))

        do {
            try audioFile.read(into: audioBuffer!)
        } catch {
            print("Error reading audio buffer: \(error)")
            return
        }

        guard let floatChannelData = audioBuffer?.floatChannelData else {
            print("Error getting float channel data")
            return
        }

        let channelData = floatChannelData.pointee
        let sampleCount = Int(audioBuffer!.frameLength)
        
        let samplesPerPoint = max(1, sampleCount / 300)

        var waveform: [Float] = []
        for i in stride(from: 0, to: sampleCount, by: samplesPerPoint) {
            var average: Float = 0
            var peak: Float = 0
            
            for j in 0..<samplesPerPoint {
                if i + j < sampleCount {
                    let sample = abs(channelData[i + j])
                    average += sample
                    peak = max(peak, sample)
                }
            }
            
            let value = (average / Float(samplesPerPoint) + peak) / 2.0
            waveform.append(value)
        }

        if let maxValue = waveform.max(), maxValue > 0 {
            for i in 0..<waveform.count {
                waveform[i] = waveform[i] / maxValue
            }
        }

        waveformData = waveform
    }
        
    private func cutSelectedAudio() {
        guard let start = selectionStart,
              let end = selectionEnd,
              let _ = player
        else {
            return
        }
        
        let startTime = duration * TimeInterval(min(start, end))
        let endTime = duration * TimeInterval(max(start, end))
        
        // temporary file of cutted audio
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let outputURL = documentsDirectory.appendingPathComponent("cut_audio_\(UUID().uuidString).m4a")
        
        let asset = AVURLAsset(url: audioURL)
            
        // Create export session
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            print("Failed to create export session")
            return
        }
            
        // Create time range for the export
        let startCMTime = CMTime(seconds: startTime, preferredTimescale: 1000)
        let endCMTime = CMTime(seconds: endTime, preferredTimescale: 1000)
        let timeRange = CMTimeRange(start: startCMTime, end: endCMTime)
            
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .m4a
        exportSession.timeRange = timeRange
            
        // Export the audio file
        exportSession.exportAsynchronously {
            DispatchQueue.main.async {
                switch exportSession.status {
                case .completed:
                    print("Audio cut successfully: \(outputURL)")
                    self.reloadAudioWithURL(outputURL)
                case .failed:
                    print("Export failed: \(String(describing: exportSession.error))")
                case .cancelled:
                    print("Export cancelled")
                default:
                    print("Export ended with status: \(exportSession.status.rawValue)")
                }
                    
                // REset
                self.selectionStart = nil
                self.selectionEnd = nil
                self.isSelectingMode = false
            }
        }
    }
    
    private func reloadAudioWithURL(_ url: URL) {
        // Stop current playback
        stopPlayback()
        
        // get new url -> rewrite the last one
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            duration = player?.duration ?? 0
            
            // Reload  data
            waveformData = []
            loadWaveformData()
        } catch {
            print("Error loading new audio file: \(error)")
        }
    }
}
