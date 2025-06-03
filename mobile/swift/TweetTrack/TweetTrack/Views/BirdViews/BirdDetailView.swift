import MapKit
import SwiftUI

struct BirdDetailView: View {
    var bird: Bird
    let manager = CLLocationManager()
    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)
    @StateObject var birdLocationFetcher = BirdLocationFetcher()
    @StateObject private var userImagesFetcher = UserImagesFetcher()
    
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @StateObject private var imageUploadViewModel = ImageUploadViewModel()
    
    let userBirdId: UUID
//      let authToken: String
    
    var body: some View {
        VStack(spacing: 20) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text(bird.name)
                            .font(.largeTitle.bold())
                            .foregroundColor(.primary)
                        Spacer()
                        ThemedButton(systemName: "speaker.wave.2.circle") {
                            print("Sound button pressed")
                        }
                    }
                    .padding(.horizontal)
                    
                    if let description = bird.description, !description.isEmpty {
                        Text(description)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                    
                    UserImagesSection(
                        images: userImagesFetcher.userImages,
                        isLoading: userImagesFetcher.isLoading,
                        errorMessage: userImagesFetcher.errorMessage
                    )
                    
                    MapCardView(
                        birdLocations: $birdLocationFetcher.birdLocation,
                        position: $position,
                        manager: manager
                    )
                    .cornerRadius(12)
                    .shadow(radius: 5)
                    .padding()
                }
            }
        }
        .task {
            await birdLocationFetcher.birdLocationFetcher()
            await userImagesFetcher.fetchUserImages(for: bird.ebird_id)
        }
    }
}

struct UserImagesSection: View {
    let images: [UserImageData]
    let isLoading: Bool
    let errorMessage: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Divider().padding(.top, 8)

            HStack {
                Text("Community Photos")
                    .font(.title3.bold())
                    .foregroundColor(.primary)
                
                Spacer()
                
                if !images.isEmpty {
                    Text("\(images.count) photo\(images.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Button {
                    print("Upload tapped")
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.accentColor)
                        .font(.title3)
                }
            }
            .padding(.horizontal)
            
            Group {
                if isLoading {
                    HStack(spacing: 10) {
                        Spacer()
                        ProgressView()
                            .scaleEffect(1)
                        Text("Loading photos...")
                            .font(.callout)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                } else if let errorMessage = errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle")
                        .font(.callout)
                        .foregroundColor(.orange)
                        .padding(.horizontal)
                } else if images.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text("No community photos yet")
                            .font(.callout)
                            .foregroundColor(.secondary)
                        Text("Be the first to share a photo!")
                            .font(.caption)
                            .foregroundColor(.accentColor)
                            .padding(.bottom, 4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .padding(.horizontal)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 16) {
                            ForEach(images, id: \.image_id) { imageData in
                                UserImageCard(imageData: imageData)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .animation(.easeInOut, value: isLoading)
        }
    }
}


struct ThemedButton: View {
    let systemName: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .resizable()
                .frame(width: 30, height: 30)
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(Circle())
                .shadow(radius: 5)
        }
    }
}
