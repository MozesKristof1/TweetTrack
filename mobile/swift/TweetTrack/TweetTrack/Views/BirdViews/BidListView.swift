import SwiftUI

struct BirdListView: View {
    @StateObject var birdFetcher = BirdFetcher()

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(birdFetcher.birds) { bird in
                    NavigationLink(destination: BirdDetailView(bird: bird)) {
                        BirdCardView(bird: bird)
                    }
                }
            }
            .padding()
        }
        .onAppear {
            Task{
                await birdFetcher.fetchBirds()
            }
        }
    }
}

#Preview {
    BirdListView(birdFetcher: BirdFetcher())
}
