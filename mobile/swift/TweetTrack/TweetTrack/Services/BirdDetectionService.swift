import Accelerate
import AudioKit
import AVFoundation
import CoreML
import Foundation

final class BirdDetectionService: ObservableObject {
    private let model: HasBirdModel
    
    init?() {
        do {
            let config = MLModelConfiguration()
            config.computeUnits = .all
            self.model = try HasBirdModel(configuration: config)
        } catch {
            print("BirdDetectionService: Failed to load ML model - \(error)")
            return nil
        }
    }
    
    func detectBirdSound(audioURL: URL) -> (String, Double) {
        do {
            let audioMultiArray = try convertAudioToMLMultiArray(audioURL: audioURL)
            
            let prediction = try model.prediction(audioSamples: audioMultiArray)
            
            if let birdProbability = prediction.targetProbability["hasbird"], birdProbability > 0.7 {
                return ("Bird detected", birdProbability)
            }
            
            if let noBirdProbability = prediction.targetProbability["nobird"] {
                return ("No bird detected", noBirdProbability)
            }
            
            return ("Undetermined", 0.0)
            
        } catch {
            return ("Error processing audio: \(error.localizedDescription)", -1.0)
        }
    }
    
    
    func convertAudioToMLMultiArray(audioURL: URL) throws -> MLMultiArray {
        // Fixed lengt for audioSamples as 15600 element vector of floats
        let targetSampleCount = 15_600
        
        let audioFile = try AVAudioFile(forReading: audioURL)
        let format = audioFile.processingFormat
        let frameCount = min(Int(audioFile.length), targetSampleCount)
        
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCount))!
        try audioFile.read(into: buffer)
        
        // Get the audio samples into an array
        guard let floatChannelData = buffer.floatChannelData else {
            throw NSError(domain: "AudioProcessing", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not get float channel data"])
        }
        
        let samplesFirstChannel = UnsafeBufferPointer(start: floatChannelData[0], count: Int(buffer.frameLength))
        
        // Create MLMultiArray
        let mlArray = try MLMultiArray(shape: [NSNumber(value: targetSampleCount)], dataType: .float32)
        
        for i in 0..<targetSampleCount {
            mlArray[i] = NSNumber(value: i < samplesFirstChannel.count ? samplesFirstChannel[i] : 0.0)
        }
        
        return mlArray
    }
    
    func segmentAudioFile(sourceAudioURL: URL, progressHandler: ((Double) -> Void)? = nil) async throws -> [URL] {
        print("🔍 Starting segmentation for: \(sourceAudioURL.lastPathComponent)")
        
        guard FileManager.default.fileExists(atPath: sourceAudioURL.path) else {
            throw NSError(domain: "AudioSegmentation", code: 1, userInfo: [NSLocalizedDescriptionKey: "Audio file not found"])
        }
        
        let audioFile = try AVAudioFile(forReading: sourceAudioURL)
        let format = audioFile.processingFormat
        let audioFileLength = audioFile.length
        
        print("📊 Audio file info:")
        print("   - Length: \(audioFileLength) frames")
        print("   - Sample rate: \(format.sampleRate) Hz")
        print("   - Duration: \(Double(audioFileLength) / format.sampleRate) seconds")
        print("   - Channels: \(format.channelCount)")
                
        let windowSize = 15_600
        let windowDuration = Double(windowSize) / format.sampleRate
        let stepSize = windowSize / 2
        
        print("🔧 Processing parameters:")
        print("   - Window size: \(windowSize) samples (\(windowDuration)s)")
        print("   - Step size: \(stepSize) samples")
        print("   - Expected iterations: \((Int(audioFileLength) - windowSize) / stepSize)")
        
        var detectedTimestamps: [TimeInterval] = []
        var processedWindows = 0
        var totalWindows = (Int(audioFileLength) - windowSize) / stepSize
        
        // Sliding Window Detection
        for i in stride(from: 0, to: Int(audioFileLength) - windowSize, by: stepSize) {
            let framePosition = AVAudioFramePosition(i)
            let currentTime = Double(framePosition) / format.sampleRate
            
            processedWindows += 1
            
            if processedWindows <= 5 || processedWindows % 100 == 0 {
                print("🔄 Processing window \(processedWindows)/\(totalWindows) at time \(String(format: "%.2f", currentTime))s")
            }
            
            guard let buffer = await readAudioChunk(from: audioFile, framePosition: framePosition, count: windowSize) else {
                print("⚠️ Failed to read audio chunk at position \(framePosition)")
                continue
            }
            
            do {
                let mlArray = try convertBufferToMLMultiArray(buffer: buffer)
                let prediction = try model.prediction(audioSamples: mlArray)
                
                if processedWindows <= 3 {
                    print("🧠 Prediction output keys: \(prediction.targetProbability.keys)")
                    print("🧠 All probabilities: \(prediction.targetProbability)")
                }
                
                if let birdProbability = prediction.targetProbability["hasbird"] {
                    if processedWindows <= 10 || birdProbability > 0.7 {
                        print("🐦 Bird probability at \(String(format: "%.2f", currentTime))s: \(String(format: "%.3f", birdProbability))")
                    }
                    
                    if birdProbability > 0.7 {
                        detectedTimestamps.append(currentTime)
                        print("✅ Bird detected at \(String(format: "%.2f", currentTime))s (confidence: \(String(format: "%.3f", birdProbability)))")
                    }
                } else {
                    print("⚠️ 'hasbird' key not found in prediction. Available keys: \(prediction.targetProbability.keys)")
                }
                
            } catch {
                print("❌ Error during ML prediction at time \(currentTime)s: \(error)")
                continue
            }
            
            let progress = Double(i) / Double(audioFileLength)
            progressHandler?(progress)
            
            let progressPercent = Int(progress * 100)
            if progressPercent % 25 == 0 && processedWindows > 1 {
                print("📈 Progress: \(progressPercent)%")
            }
        }
        
        print("🎯 Detection complete. Found \(detectedTimestamps.count) potential bird sounds")
        
        //Merge Consecutive Detections
        let segments = mergeDetections(timestamps: detectedTimestamps, windowDuration: windowDuration)
        print("🔗 After merging: \(segments.count) segments")
        
        for (index, segment) in segments.enumerated() {
            print("   Segment \(index + 1): \(String(format: "%.2f", segment.startTime))s - \(String(format: "%.2f", segment.endTime))s (duration: \(String(format: "%.2f", segment.endTime - segment.startTime))s)")
        }
        
        //Extract and save
        let outputURLs = try await extractSegments(from: sourceAudioURL, segments: segments)
        
        progressHandler?(1.0)
        print("✅ Segmentation complete. Created \(outputURLs.count) audio files")
        return outputURLs
    }
    

    private func readAudioChunk(from audioFile: AVAudioFile, framePosition: AVAudioFramePosition, count: Int) async -> AVAudioPCMBuffer? {
        if framePosition >= audioFile.length {
            print("⚠️ Frame position \(framePosition) exceeds file length \(audioFile.length)")
            return nil
        }
        
        audioFile.framePosition = framePosition
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat, frameCapacity: AVAudioFrameCount(count)) else {
            print("❌ Failed to create PCM buffer")
            return nil
        }
        
        do {
            let framesToRead = min(count, Int(audioFile.length - framePosition))
            try audioFile.read(into: buffer, frameCount: AVAudioFrameCount(framesToRead))
            
            if buffer.frameLength == 0 {
                print("⚠️ Read 0 frames from audio file")
                return nil
            }
            
            return buffer
        } catch {
            print("❌ Error reading audio chunk: \(error)")
            return nil
        }
    }
    

    private func convertBufferToMLMultiArray(buffer: AVAudioPCMBuffer) throws -> MLMultiArray {
        let targetSampleCount = 15_600
        let mlArray = try MLMultiArray(shape: [NSNumber(value: targetSampleCount)], dataType: .float32)
        
        guard let channelData = buffer.floatChannelData?[0] else {
            throw NSError(domain: "AudioProcessing", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not get float channel data from buffer."])
        }
        
        let frameLength = Int(buffer.frameLength)
        
        if frameLength == 0 {
            print("⚠️ Buffer has 0 frames")
        }
        

        for i in 0..<targetSampleCount {
            if i < frameLength {
                mlArray[i] = NSNumber(value: channelData[i])
            } else {
                mlArray[i] = NSNumber(value: 0.0)
            }
        }
        
        var conversionCount = 0
        conversionCount += 1
        if conversionCount <= 3 {
            let audioData = Array(UnsafeBufferPointer(start: channelData, count: min(frameLength, 10)))
            print("🔊 Audio sample (first 10 values): \(audioData.map { String(format: "%.3f", $0) }.joined(separator: ", "))")
        }
        
        return mlArray
    }
    
    private func mergeDetections(timestamps: [TimeInterval], windowDuration: TimeInterval) -> [DetectedSegment] {
           guard !timestamps.isEmpty else { return [] }

           var segments: [DetectedSegment] = []
           var currentSegment: DetectedSegment?

           for timestamp in timestamps.sorted() {
               if var segment = currentSegment {
                   // If the new timestamp is close enough to the end of the current segment, merge them.
                   if timestamp <= segment.endTime {
                       segment.endTime = timestamp + windowDuration
                       currentSegment = segment
                   } else {
                       // New segment
                       segments.append(segment)
                       currentSegment = DetectedSegment(startTime: timestamp, endTime: timestamp + windowDuration)
                   }
               } else {
                   currentSegment = DetectedSegment(startTime: timestamp, endTime: timestamp + windowDuration)
               }
           }

           if let lastSegment = currentSegment {
               segments.append(lastSegment)
           }

           return segments
       }
    

    private func extractSegments(from sourceURL: URL, segments: [DetectedSegment]) async throws -> [URL] {
        var outputURLs: [URL] = []
        let asset = AVURLAsset(url: sourceURL)
        
        let totalDuration = try await asset.load(.duration).seconds
        
        print("🎬 Starting segment extraction for \(segments.count) segments. Total audio duration: \(totalDuration)s")

                
        for (index, segment) in segments.enumerated() {
            
            let segmentDuration = segment.endTime - segment.startTime
            print("📁 Preparing to extract segment \(index + 1): Start=\(segment.startTime)s, End=\(segment.endTime)s, Duration=\(segmentDuration)s")

            
            print("📁 Extracting segment \(index + 1)/\(segments.count)...")
            
            let startTime = CMTime(seconds: segment.startTime, preferredTimescale: 600)
            let endTime = CMTime(seconds: segment.endTime, preferredTimescale: 600)
            let timeRange = CMTimeRange(start: startTime, end: endTime)
            
            guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
                print("❌ Failed to create export session for segment \(index)")
                continue
            }
            
            let outputURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("bird_segment_\(index)_\(UUID().uuidString)")
                .appendingPathExtension("m4a")
            
            exportSession.outputURL = outputURL
            exportSession.outputFileType = .m4a
            exportSession.timeRange = timeRange
            
            await exportSession.export()
            
            switch exportSession.status {
            case .completed:
                print("✅ Successfully exported segment \(index + 1) to: \(outputURL.lastPathComponent)")
                outputURLs.append(outputURL)
            case .failed:
                print("❌ Export failed for segment \(index + 1): \(exportSession.error?.localizedDescription ?? "Unknown error")")
            case .cancelled:
                print("⚠️ Export cancelled for segment \(index + 1)")
            default:
                print("⚠️ Export status for segment \(index + 1): \(exportSession.status.rawValue)")
            }
        }
        
        print("📦 Segment extraction complete. Successfully created \(outputURLs.count)/\(segments.count) files")
        return outputURLs
    }
}

struct DetectedSegment {
    var startTime: TimeInterval
    var endTime: TimeInterval
}
