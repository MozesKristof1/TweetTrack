import MapKit
import SwiftUI

struct BirdDetailView: View {
    var bird: Bird
    let manager = CLLocationManager()
    @State private var position: MapCameraPosition =
        .userLocation(fallback: .automatic)

    var body: some View {
        VStack {
            Text(bird.name)
                .font(.largeTitle)
                .padding()

            Text(bird.description)
                .font(.body)
                .padding()

            Spacer()
            
            MapCard(position: $position, manager: manager)
            
        }
        .padding()
    }
}

#Preview {
    BirdListView(birdFetcher: BirdFetcher())
}
