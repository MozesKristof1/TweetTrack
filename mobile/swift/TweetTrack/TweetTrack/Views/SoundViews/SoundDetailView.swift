import SwiftUI

struct SoundDetailView: View {
    @Bindable var sound: BirdSoundItem
    let detectionService: BirdDetectionService
    let postService: AudioUploadService
    
    @State private var detectionResult: String
    @State private var errorMessage: String?
    @State private var isIdentifying: Bool = false
    
    @Environment(\.modelContext) private var context
    
    init(sound: BirdSoundItem, detectionService: BirdDetectionService, postService: AudioUploadService) {
        self.sound = sound
        self.detectionService = detectionService
        self.postService = postService
        self._detectionResult = State(initialValue: detectionService.detectBirdSound(audioURL: URL(fileURLWithPath: sound.audioDataPath)).0)
        
        if detectionResult == "Bird detected" {
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
                
                Text(detectionResult)
                    .font(.headline)
                    .foregroundColor(.gray)
                    .padding()
                
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
                            
                            if let confidence = sound.confidence {
                                Text(String(format: "Confidence: %.2f%%", confidence * 100))
                                    .font(.caption)
                                    .padding(8)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                            }
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
                        probability: identification.4
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
    
    private func parseBirdIdentification(_ data: Data) throws -> (String, String, String, String, Double) {
           struct BirdIdentification: Codable {
               let commonName: String
               let scientificName: String
               let identificationText: String
               let imageUrl: String
               let probability: Double
               
               enum CodingKeys: String, CodingKey {
                   case commonName = "common_name"
                   case scientificName = "scientific_name"
                   case identificationText = "identification_text"
                   case imageUrl = "image_url"
                   case probability
               }
           }
           
           let decoder = JSONDecoder()
           let identification = try decoder.decode(BirdIdentification.self, from: data)
           
           return (
               identification.commonName,
               identification.scientificName,
               identification.identificationText,
               identification.imageUrl,
               identification.probability
           )
       }
    
}
