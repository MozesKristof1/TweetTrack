import MapKit
import SwiftUI
import CoreLocation


struct BirdDetailView: View {
    var bird: Bird
    let manager = CLLocationManager()
    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)
    @StateObject var birdLocationFetcher = BirdLocationFetcher()
    @StateObject private var userImagesFetcher = UserImagesFetcher()
    
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var showObservationSheet = false
    @StateObject private var observationViewModel = ObservationViewModel()
    @StateObject private var imageUploadViewModel = ImageUploadViewModel()
    
    @StateObject private var locationManager = LocationManager()
    
    @EnvironmentObject var authService: AuthService

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
                        errorMessage: userImagesFetcher.errorMessage,
                        onUploadTapped: {
                            if authService.isLoggedIn {
                                showObservationSheet = true
                            } else {
                                // TODO: make ui for this
                                print("User not logged in")
                            }
                        }
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
        .sheet(isPresented: $showObservationSheet) {
            CreateObservationSheet(
                bird: bird,
                observationViewModel: observationViewModel,
                imageUploadViewModel: imageUploadViewModel,
                userToken: authService.accessToken,
                userLocation: locationManager.location,
                onComplete: {
                    Task {
                        await userImagesFetcher.fetchUserImages(for: bird.ebird_id)
                    }
                }
            )
        }
        .task {
            await birdLocationFetcher.birdLocationFetcher()
            await userImagesFetcher.fetchUserImages(for: bird.ebird_id)
        }
        .onAppear {
            locationManager.requestLocation()
        }
    }
}

struct StepIndicator: View {
    let step: Int
    let title: String
    let isActive: Bool
    let isCompleted: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(isCompleted ? Color.green : (isActive ? Color.accentColor : Color.gray))
                    .frame(width: 30, height: 30)
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                        .font(.caption.bold())
                } else {
                    Text("\(step)")
                        .foregroundColor(.white)
                        .font(.caption.bold())
                }
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(isActive ? .primary : .secondary)
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
