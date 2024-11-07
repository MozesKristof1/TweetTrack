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

            Map(position: $position) {
                UserAnnotation()
            }
            .mapControls{
                MapUserLocationButton()
            }
            .frame(height: 300)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 4)
            .padding()
            .onAppear {
                manager.requestWhenInUseAuthorization()
            }
            
            
            
        }
        .padding()
    }
}

#Preview {
    BirdListView(birdFetcher: BirdFetcher())
}
