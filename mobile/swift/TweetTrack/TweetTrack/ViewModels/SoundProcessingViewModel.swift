import Foundation
import AVFAudio

class SoundProcessingViewModel: ObservableObject {
    
    @Published var isProcessing = false
    @Published var newSoundItems: [BirdSoundItem] = []
    @Published var processingStatus = "Ready"
    @Published var detectionCount = 0
    
    private let detectionService = BirdDetectionService()
    
    func processAndSegment(item: BirdSoundItem) {
        print("🚀 Starting processAndSegment for item: \(item.title)")
        print("📂 Audio data path: \(item.audioDataPath)")
        
        guard !isProcessing else {
            print("⚠️ Already processing, ignoring request")
            return
        }
        
        guard let service = detectionService else {
            print("❌ Detection service is nil")
            return
        }
        
        isProcessing = true
        processingStatus = "Initializing..."
        newSoundItems.removeAll()
        detectionCount = 0


        // Check file size
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: item.audioDataPath)
            let fileSize = attributes[.size] as? Int64 ?? 0
            print("📊 File size: \(fileSize) bytes")
        } catch {
            print("⚠️ Could not get file attributes: \(error)")
        }
        
        let sourceURL = URL(fileURLWithPath: item.audioDataPath)

        Task {
            do {
                await MainActor.run {
                    self.processingStatus = "Analyzing audio..."
                }
                
                
                let segmentURLs = try await service.segmentAudioFile(sourceAudioURL: sourceURL) { progress in
                        DispatchQueue.main.async {
                            self.processingStatus = "Processing... \(Int(progress * 100))%"
                            print("📈 Processing progress: \(Int(progress * 100))%")
                        }
                    }
                
                print("🎯 Segmentation returned \(segmentURLs.count) URLs")
                
                // Create new BirdSoundItem objects for each segment
                var createdItems: [BirdSoundItem] = []
                for (index, url) in segmentURLs.enumerated() {
                    print("📁 Processing segment URL \(index + 1): \(url.lastPathComponent)")
                    
                    let newFileName = url.lastPathComponent
                    
                    // Try to get actual duration from the audio file
                    var duration: Double = 0.0
                    do {
                        let audioFile = try AVAudioFile(forReading: url)
                        duration = Double(audioFile.length) / audioFile.processingFormat.sampleRate
                        print("⏱️ Segment \(index + 1) duration: \(String(format: "%.2f", duration))s")
                    } catch {
                        print("⚠️ Could not read duration for segment \(index + 1): \(error)")
                        duration = 5.0 // Default fallback
                    }
                    
                    let newItem = BirdSoundItem(
                        title: "\(item.title) - Segment \(index + 1)",
                        audioDataPath: newFileName,
                        duration: duration
                    )
                    newItem.detectedBird = true
                    createdItems.append(newItem)
                }
                
                // Update the UI on the main thread
                await MainActor.run {
                    self.newSoundItems = createdItems
                    self.isProcessing = false
                    self.detectionCount = createdItems.count
                    self.processingStatus = createdItems.isEmpty ? "No bird sounds detected" : "Found \(createdItems.count) segments"
                    print("✅ Successfully created \(createdItems.count) segments.")
                }
                
            } catch {
                await MainActor.run {
                    self.isProcessing = false
                    self.processingStatus = "Error: \(error.localizedDescription)"
                    print("❌ Error during segmentation: \(error)")
                }
            }
        }
    }
}


