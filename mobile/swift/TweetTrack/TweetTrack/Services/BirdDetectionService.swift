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
            print("BirdSoundIdentifierService: Failed to load ML model - \(error)")
            return nil
        }
    }
    
    func detectBirdSound(audioURL: URL) -> String {
        do {
            let audioMultiArray = try convertAudioToMLMultiArray(audioURL: audioURL)
            
            // Perform prediction with the model
            let prediction = try model.prediction(audioSamples: audioMultiArray)
            print(prediction.targetProbability)

            if (prediction.targetProbability["hasbird"] ?? 0.0) > 0.7 {
                return "Bird detected"
            }
            
            return "No bird detected"
            
        } catch {
            return "Error processing audio: \(error.localizedDescription)"
        }
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
