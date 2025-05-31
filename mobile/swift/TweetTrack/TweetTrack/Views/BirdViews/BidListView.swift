import SwiftUI

struct BirdListView: View {
    @StateObject var birdFetcher = BirdFetcher()
    @State private var searchText = ""

    var filteredBirds: [Bird] {
        if searchText.isEmpty {
            return birdFetcher.birds
        } else {
            return birdFetcher.birds.filter { bird in
                bird.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(filteredBirds) { bird in
                        NavigationLink(destination: BirdDetailView(bird: bird)) {
                            BirdCardView(bird: bird)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle("Birds")
            .searchable(text: $searchText, prompt: "Search by bird name")
            .onAppear {
                if birdFetcher.birds.isEmpty {
                    Task {
                        await birdFetcher.fetchBirds()
                    }
                }
            }
        }
    }
}

#Preview {
    BirdListView()
}
