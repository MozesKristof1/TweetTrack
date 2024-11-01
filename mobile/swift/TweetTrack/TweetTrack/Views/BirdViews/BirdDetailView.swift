import SwiftUI

struct BirdDetailView: View {
    var bird: Bird

    var body: some View {
        VStack {
            Text(bird.name)
                .font(.largeTitle)
                .padding()

            Text(bird.description)
                .font(.body)
                .padding()

            Spacer()
        }
        .padding()
    }
}

#Preview {
    BirdListView(birdFetcher: BirdFetcher())
}
