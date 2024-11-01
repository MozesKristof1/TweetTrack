import SwiftUI

struct BirdListView: View {
    @StateObject var birdFetcher = BirdFetcher()

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(birdFetcher.birds) { bird in
                    NavigationLink(destination: BirdDetailView(bird: bird)) {
                        HStack {
                            if let data = Data(base64Encoded: bird.base64Picture, options: .ignoreUnknownCharacters),
                               let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 100, height: 100)
                                    .cornerRadius(25)
                            } else {
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100, height: 100)
                                    .foregroundColor(.gray)
                            }
                            
                            VStack(alignment: .leading) {
                                Text(bird.name)
                                    .font(.headline)
                                Text(bird.description)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .lineSpacing(0.5)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(radius: 4)
                    }
                }
            }
            .padding()
        }
        .onAppear {
            birdFetcher.fetchBirds()
        }
    }
}

#Preview {
    BirdListView(birdFetcher: BirdFetcher())
}
