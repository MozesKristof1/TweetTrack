import MapKit
import SwiftUI

struct BirdDetailView: View {
    var bird: Bird
    let manager = CLLocationManager()
    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)
    @StateObject var birdLocationFetcher = BirdLocationFetcher()
    
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
                    
                    Text(bird.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    MapCardView(birdLocations: $birdLocationFetcher.birdLocation, position: $position, manager: manager)
                        .cornerRadius(12)
                        .shadow(radius: 5)
                        .padding()
                }
            }
            
            HStack {
                Spacer()
                ThemedButton(systemName: "plus.app.fill") {
                    print("Add button pressed")
                }
            }
            .padding(.trailing, 20)
            .padding(.bottom, 20)
        }
        .task {
            await birdLocationFetcher.birdLocationFetcher()
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

#Preview {
    BirdListView(birdFetcher: BirdFetcher())
}
