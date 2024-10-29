import Foundation

class BirdFetcher: ObservableObject {
    @Published var birds: [Bird] = []

    func fetchBirds() {
        let urlString = Api.birdsEndpoint
        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else { return }

            do {
                let decodedData = try JSONDecoder().decode([Bird].self, from: data)
                DispatchQueue.main.async {
                    self.birds = decodedData
                }
            } catch {
                print("Error : \(error)")
            }
        }.resume()
    }
}
