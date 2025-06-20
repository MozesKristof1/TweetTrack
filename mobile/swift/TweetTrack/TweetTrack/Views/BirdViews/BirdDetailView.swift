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
    @State private var showImageViewer = false
    @State private var selectedImageForViewing: UIImage?
    
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
                        },
                        onImageTapped: { image in
                            selectedImageForViewing = image
                            showImageViewer = true
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
            ObservationSheet(
                bird: bird,
                observationViewModel: observationViewModel,
                imageUploadViewModel: imageUploadViewModel,
                userToken: authService.accessToken ?? "",
                userLocation: locationManager.location,
                onComplete: {
                    Task {
                        await userImagesFetcher.fetchUserImages(for: bird.ebird_id)
                    }
                }
            )
        }
        .fullScreenCover(isPresented: $showImageViewer) {
            ImageViewerSheet(
                image: selectedImageForViewing,
                isPresented: $showImageViewer
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

struct ImageViewerSheet: View {
    let image: UIImage?
    @Binding var isPresented: Bool
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack {
                HStack {
                    Spacer()
                    Button("Done") {
                        isPresented = false
                    }
                    .foregroundColor(.white)
                    .padding()
                }
                
                Spacer()
                
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            SimultaneousGesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        scale = lastScale * value
                                    }
                                    .onEnded { _ in
                                        if scale < 1 {
                                            withAnimation(.spring()) {
                                                scale = 1
                                                offset = .zero
                                            }
                                        } else if scale > 4 {
                                            withAnimation(.spring()) {
                                                scale = 4
                                            }
                                        }
                                        lastScale = scale
                                    },
                                DragGesture()
                                    .onChanged { value in
                                        if scale > 1 {
                                            offset = CGSize(
                                                width: lastOffset.width + value.translation.width,
                                                height: lastOffset.height + value.translation.height
                                            )
                                        }
                                    }
                                    .onEnded { _ in
                                        lastOffset = offset
                                    }
                            )
                        )
                        .onTapGesture(count: 2) {
                            withAnimation(.spring()) {
                                if scale == 1 {
                                    scale = 2
                                    lastScale = 2
                                } else {
                                    scale = 1
                                    lastScale = 1
                                    offset = .zero
                                    lastOffset = .zero
                                }
                            }
                        }
                }
                
                Spacer()
            }
        }
        .onAppear {
            // Reset zoom when sheet appears
            scale = 1.0
            lastScale = 1.0
            offset = .zero
            lastOffset = .zero
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
