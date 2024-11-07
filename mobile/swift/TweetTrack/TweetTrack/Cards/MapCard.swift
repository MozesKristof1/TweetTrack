import MapKit
import SwiftUI

struct MapCard: View {
    @Binding var position: MapCameraPosition
    let manager: CLLocationManager

    var body: some View {
        Map(position: $position) {
            UserAnnotation()
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
