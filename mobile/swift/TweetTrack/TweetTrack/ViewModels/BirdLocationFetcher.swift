import Foundation

class BirdLocationFetcher: ObservableObject {
    @Published var birdLocation: [BirdLocation] = []
    
    func birdLocationFetcher() async {
        let urlString = Api.birdLocationsEndpoint
        guard let url = URL(string: urlString) else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            let decodedData = try JSONDecoder().decode([BirdLocation].self, from: data)
            
            DispatchQueue.main.async {
                self.birdLocation = decodedData
            }
        } catch {
            print("Error fetching bird locations: \(error)")
        }
    }
}
