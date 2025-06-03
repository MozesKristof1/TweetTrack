import Foundation

@MainActor
class UserImagesFetcher: ObservableObject {
    @Published var userImages: [UserImageData] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func fetchUserImages(for ebirdId: String?) async {
        guard let ebirdId = ebirdId, !ebirdId.isEmpty else {
            await MainActor.run {
                self.errorMessage = "No bird ID available"
            }
            return
        }
        
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        
        let urlString = Api.birdUserImages(ebirdId)
        
        guard let url = URL(string: urlString) else { return }

        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode != 200 {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = "Server error (\(httpResponse.statusCode))"
                }
                return
            }
            
            let userImageResponse = try JSONDecoder().decode(UserImageResponse.self, from: data)
            
            await MainActor.run {
                self.userImages = userImageResponse.images
                self.isLoading = false
                print("Successfully loaded \(userImageResponse.images.count) user images")
            }
            
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = "Failed to load photos"
                print("Error fetching user images: \(error)")
            }
        }
    }
}
