import MapKit
import SwiftUI

struct BirdDetailView: View {
    var bird: Bird
    let manager = CLLocationManager()
    @State private var position: MapCameraPosition =
        .userLocation(fallback: .automatic)
    @StateObject var birdLocationFetcher = BirdLocationFetcher()

    var body: some View {
        ScrollView {
            VStack() {
                Text(bird.name)
                    .font(.largeTitle)
                    .padding()
                
                Text(bird.description)
                    .font(.body)
                    .padding()
                
                Spacer()
                MapCardView(birdLocations: $birdLocationFetcher.birdLocation, position: $position, manager: manager)
            
            }
            .padding()
            .onAppear{
                Task{
                    await birdLocationFetcher.birdLocationFetcher()
                }
            }
        }
    }
}

#Preview {
    BirdListView(birdFetcher: BirdFetcher())
}
