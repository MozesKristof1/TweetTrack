import Foundation

class BirdFetcher: ObservableObject {
    @Published var birds: [Bird] = []

    func fetchBirds() async {
        let urlString = Api.birdsEndpoint
        guard let url = URL(string: urlString) else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)

            let decodedData = try JSONDecoder().decode([Bird].self, from: data)

            DispatchQueue.main.async {
                self.birds = decodedData
            }
        } catch {
            print("Error fetching birds: \(error)")
        }
    }
}
