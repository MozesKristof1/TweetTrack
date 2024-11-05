import MapKit
import SwiftUI

struct BirdDetailView: View {
    var bird: Bird
    @State private var position = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1)
        )
    )

    var body: some View {
        VStack {
            Text(bird.name)
                .font(.largeTitle)
                .padding()

            Text(bird.description)
                .font(.body)
                .padding()
            Spacer()

            Map(position: $position, interactionModes: [.all])
                .frame(height: 300)
                .cornerRadius(25)
                .padding()
        }
        .padding()
    }
}

#Preview {
    BirdListView(birdFetcher: BirdFetcher())
}
