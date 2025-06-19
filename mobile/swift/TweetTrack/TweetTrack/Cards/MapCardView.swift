import MapKit
import SwiftUI

struct MapCardView: View {
    @Binding var birdLocations: [BirdLocation]
    @Binding var position: MapCameraPosition
    let manager: CLLocationManager

    var body: some View {
        Map(position: $position) {
            UserAnnotation()
            ForEach(birdLocations) { birdLocation in
                Marker(
                    coordinate: CLLocationCoordinate2D(latitude: CLLocationDegrees(birdLocation.latitude), longitude: CLLocationDegrees(birdLocation.longitude))
                ) {
                    Label("", systemImage: "bird")
                }
                .tint(.red)
            }
        }
        .mapControls {
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
}
