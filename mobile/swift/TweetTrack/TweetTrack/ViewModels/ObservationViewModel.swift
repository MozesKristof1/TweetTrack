import Foundation

@MainActor
class ObservationViewModel: ObservableObject {
    @Published var isCreatingObservation = false
    @Published var observationMessage: String?
    @Published var createdObservation: BirdObservationResponse?
    
    func createObservation(
        bird: Bird,
        latitude: Double,
        longitude: Double,
        notes: String?,
        token: String
    ) async {
        isCreatingObservation = true
        observationMessage = nil
        
        let observation = BirdObservationCreate(
            ebird_id: bird.ebird_id!,
            latitude: latitude,
            longitude: longitude,
            observed_at: Date(),
            notes: notes
        )
        
    
        var request = URLRequest(url: URL(string: Api.observations)!)
        
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            request.httpBody = try encoder.encode(observation)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                observationMessage = "No response from server"
                isCreatingObservation = false
                return
            }
            
            if httpResponse.statusCode == 201 {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                createdObservation = try decoder.decode(BirdObservationResponse.self, from: data)
                observationMessage = "Observation created successfully!"
            } else {
                let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
                observationMessage = "Failed to create observation: \(errorText)"
            }
        } catch {
            observationMessage = "Error creating observation: \(error.localizedDescription)"
        }
        
        isCreatingObservation = false
    }
}
