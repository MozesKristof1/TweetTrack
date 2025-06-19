import SwiftUI

struct SoundDetailView: View {
    @Bindable var sound: BirdSoundItem
    let detectionService: BirdDetectionService
    let postService: AudioUploadService
    
    @State private var detectionResult: String?
    @State private var errorMessage: String?
    @State private var isIdentifying: Bool = false
    @State private var showTaxonomy = false
    
    @StateObject private var segmentationViewModel = SoundProcessingViewModel()
    @State private var showSegmentationResults = false

    @Environment(\.modelContext) private var context
    
    @StateObject private var audioPlayerService = AudioPlayerService()

    init(sound: BirdSoundItem, detectionService: BirdDetectionService, postService: AudioUploadService) {
        self.sound = sound
        self.detectionService = detectionService
        self.postService = postService

        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fullAudioURL = documentsDirectory.appendingPathComponent(sound.audioDataPath)

        let initialDetection = detectionService.detectBirdSound(audioURL: fullAudioURL).0
        self._detectionResult = State(initialValue: initialDetection)
        
        if initialDetection == "Bird detected" {
            sound.detectedBird = true
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text(sound.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .padding()
                
                // Updated AudioWaveformView with playback
                AudioWaveformView(audioURL: URL(fileURLWithPath: sound.audioDataPath))
                    .frame(height: 150)
                    .padding(.horizontal)
                
                Text("Bird detected")
                    .font(.headline)
                    .foregroundColor(.gray)
                    .padding()
                
                // Auto Segmentation Button
                Button(action: {
                    segmentationViewModel.processAndSegment(item: sound)
                }) {
                    HStack {
                        if segmentationViewModel.isProcessing {
                            ProgressView()
                                .scaleEffect(0.8)
                                .padding(.trailing, 5)
                        }
                        Text(segmentationViewModel.isProcessing ? "Segmenting Audio..." : " Auto Segment Audio")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(segmentationViewModel.isProcessing ? Color.gray : Color.green)
                    .cornerRadius(10)
                    .disabled(segmentationViewModel.isProcessing)
                }
                .padding(.horizontal, 20)
                
                // Show segmentation results
                if !segmentationViewModel.newSoundItems.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Generated Segments (\(segmentationViewModel.newSoundItems.count))")
                                .font(.headline)
                                .foregroundColor(.green)
                            
                            Spacer()
                            
                            Button("Save All") {
                                saveSegmentedSounds()
                            }
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        
                        LazyVStack(spacing: 8) {
                            ForEach(segmentationViewModel.newSoundItems, id: \.id) { segmentItem in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(segmentItem.title)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        Text("Duration: \(String(format: "%.1f", segmentItem.duration))s")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    // Mini waveform or play button could go here
//                                    Button(action: {
//                                        audioPlayerService.playAudio(at: segmentItem.audioDataPath)
//                                    }) {
//                                        Image(systemName: "waveform")
//                                            .foregroundColor(.green)
//                                    }
                                    
                                }
                                .padding(8)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                    }
                }
                if sound.birdName == nil {
                    Button(action: identifyBird) {
                        Text(isIdentifying ? "Identifying..." : "Identify the Bird")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(isIdentifying ? Color.gray : Color.blue)
                            .cornerRadius(10)
                            .disabled(isIdentifying)
                    }
                    .padding(.horizontal, 20)
                }
                
                if sound.confidence != nil && sound.confidence! == 0.7 {
                    Text("Couldn't identify the bird due to low confidence score.")
                        .foregroundColor(.orange)
                        .padding()
                        .background(Color.orange.opacity(0.15))
                        .cornerRadius(8)
                } else {
                    if let birdName = sound.birdName {
                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(birdName)
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    
                                    if let scientificName = sound.scientificName {
                                        Text(scientificName)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                            }
                            
                            if let description = sound.birdDescription {
                                Text("Description:")
                                    .font(.headline)
                                
                                Text(description)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                            
                            if let imageUrl = sound.imageUrl {
                                AsyncImage(url: URL(string: imageUrl)) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .cornerRadius(10)
                                } placeholder: {
                                    ProgressView()
                                }
                                .frame(height: 200)
                            }
                            HStack {
                                Spacer()
                                Button(action: {
                                    showTaxonomy = true
                                }) {
                                    Text("🧬")
                                        .font(.title)
                                        .padding(8)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(8)
                                }
                                Spacer()
                            }
                            Spacer()
                        }
                        .sheet(isPresented: $showTaxonomy) {
                            NavigationStack {
                                TaxonomyCardView(sound: sound)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(15)
                        .padding(.horizontal)
                    }
                    
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding()
                    }
                }
            }
            .padding()
        }
    }

    private func identifyBird() {
        isIdentifying = true
        errorMessage = nil
        
        let fileURL = URL(fileURLWithPath: sound.audioDataPath)
        postService.uploadSoundFile(fileURL: fileURL) { [self] result in
            switch result {
            case .success(let data):
                do {
                    print(data)
                    let identification = try parseBirdIdentification(data)
                    
                    print(identification)
                    sound.updateBirdIdentification(
                        name: identification.0,
                        scientificName: identification.1,
                        identificationText: identification.2,
                        imageUrl: identification.3,
                        probability: identification.4,
                        genus: identification.5,
                        family: identification.6,
                        order: identification.7
                    )
                    
                    try? context.save()
                    
                    detectionResult = "Bird identified successfully!"
                } catch {
                    errorMessage = "Error parsing bird identification: \(error.localizedDescription)"
                }
            case .failure(let error):
                errorMessage = "Upload failed: \(error.localizedDescription)"
            }
            
            isIdentifying = false
        }
    }
    
    private func saveSegmentedSounds() {
        for segmentItem in segmentationViewModel.newSoundItems {
            context.insert(segmentItem)
        }
        
        do {
            try context.save()
            segmentationViewModel.newSoundItems.removeAll()
        } catch {
            errorMessage = "Failed to save segmented sounds: \(error.localizedDescription)"
        }
    }
    
    private func parseBirdIdentification(_ data: Data) throws -> (String, String, String, String, Double, String?, String?, String?) {
        struct BirdIdentification: Codable {
            let commonName: String
            let scientificName: String
            let identificationText: String
            let imageUrl: String
            let probability: Double
            let genus: String?
            let family: String?
            let order: String?
               
            enum CodingKeys: String, CodingKey {
                case commonName = "common_name"
                case scientificName = "scientific_name"
                case identificationText = "identification_text"
                case imageUrl = "image_url"
                case probability
                case genus
                case family
                case order
            }
        }
           
        let decoder = JSONDecoder()
        let identification = try decoder.decode(BirdIdentification.self, from: data)
           
        return (
            identification.commonName,
            identification.scientificName,
            identification.identificationText,
            identification.imageUrl,
            identification.probability,
            identification.genus,
            identification.family,
            identification.order
        )
    }
}
