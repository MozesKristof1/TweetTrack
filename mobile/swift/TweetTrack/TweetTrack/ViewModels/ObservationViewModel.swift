import Foundation

@MainActor
class ObservationViewModel: ObservableObject {
    @Published var isCreatingObservation = false
    @Published var isLoadingObservations = false
    @Published var observationMessage: String?
    @Published var createdObservation: BirdObservationResponse?
    @Published var userObservations: [BirdObservationResponse] = []
    @Published var myObservations: [BirdObservationResponse] = []
    
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
    
    func loadUserObservations(birdEBirdId: String, token: String) async {
        isLoadingObservations = true
        observationMessage = nil
        userObservations = []
        
        guard let url = URL(string: Api.observations) else {
            observationMessage = "Invalid URL"
            isLoadingObservations = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                observationMessage = "No response from server"
                isLoadingObservations = false
                return
            }
            
            if httpResponse.statusCode == 200 {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .custom { decoder in
                    let container = try decoder.singleValueContainer()
                    let dateString = try container.decode(String.self)
                    
                    // ISO8601
                    let iso8601Formatter = ISO8601DateFormatter()
                    iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    if let date = iso8601Formatter.date(from: dateString) {
                        return date
                    }
                    
                    iso8601Formatter.formatOptions = [.withInternetDateTime]
                    if let date = iso8601Formatter.date(from: dateString) {
                        return date
                    }
                    
                    // standard ISO8601
                    let standardFormatter = DateFormatter()
                    standardFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                    if let date = standardFormatter.date(from: dateString) {
                        return date
                    }
                    
                    throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string \(dateString)")
                }
                
                let allObservations = try decoder.decode([BirdObservationResponse].self, from: data)
                
                // get observations for the specific bird
                userObservations = allObservations.filter { observation in
                    observation.ebird_id == birdEBirdId
                }
                
                print("Loaded \(userObservations.count) observations for bird \(birdEBirdId)")
            } else {
                let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
                observationMessage = "Failed to load observations: \(errorText)"
                print("HTTP Error \(httpResponse.statusCode): \(errorText)")
            }
        } catch let decodingError as DecodingError {
            print("Decoding error: \(decodingError)")
            switch decodingError {
            case .keyNotFound(let key, _):
                observationMessage = "Missing key '\(key.stringValue)' in response"
            case .typeMismatch(let type, let context):
                observationMessage = "Type mismatch for type \(type) at \(context.codingPath)"
            case .valueNotFound(let type, let context):
                observationMessage = "Value not found for type \(type) at \(context.codingPath)"
            case .dataCorrupted(let context):
                observationMessage = "Data corrupted: \(context.debugDescription)"
            @unknown default:
                observationMessage = "Unknown decoding error: \(decodingError.localizedDescription)"
            }
        } catch {
            observationMessage = "Error loading observations: \(error.localizedDescription)"
            print("General error: \(error)")
        }
        
        isLoadingObservations = false
    }
    
    func loadMyObservations(token: String) async {
        isLoadingObservations = true
        observationMessage = nil
        myObservations = []
            
        guard let url = URL(string: Api.myObservations) else {
            observationMessage = "Invalid URL"
            isLoadingObservations = false
            return
        }
            
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
                
            guard let httpResponse = response as? HTTPURLResponse else {
                observationMessage = "No response from server"
                isLoadingObservations = false
                return
            }
                
            if httpResponse.statusCode == 200 {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .custom { decoder in
                    let container = try decoder.singleValueContainer()
                    let dateString = try container.decode(String.self)
                        
                    // ISO8601
                    let iso8601Formatter = ISO8601DateFormatter()
                    iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    if let date = iso8601Formatter.date(from: dateString) {
                        return date
                    }
                        
                    iso8601Formatter.formatOptions = [.withInternetDateTime]
                    if let date = iso8601Formatter.date(from: dateString) {
                        return date
                    }
                        
                    // standard ISO8601
                    let standardFormatter = DateFormatter()
                    standardFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                    if let date = standardFormatter.date(from: dateString) {
                        return date
                    }
                        
                    throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string \(dateString)")
                }
                    
                myObservations = try decoder.decode([BirdObservationResponse].self, from: data)
                print("Loaded \(myObservations.count) observations for current user")
            } else {
                let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
                observationMessage = "Failed to load observations: \(errorText)"
                print("HTTP Error \(httpResponse.statusCode): \(errorText)")
            }
        } catch let decodingError as DecodingError {
            print("Decoding error: \(decodingError)")
            switch decodingError {
            case .keyNotFound(let key, _):
                observationMessage = "Missing key '\(key.stringValue)' in response"
            case .typeMismatch(let type, let context):
                observationMessage = "Type mismatch for type \(type) at \(context.codingPath)"
            case .valueNotFound(let type, let context):
                observationMessage = "Value not found for type \(type) at \(context.codingPath)"
            case .dataCorrupted(let context):
                observationMessage = "Data corrupted: \(context.debugDescription)"
            @unknown default:
                observationMessage = "Unknown decoding error: \(decodingError.localizedDescription)"
            }
        } catch {
            observationMessage = "Error loading observations: \(error.localizedDescription)"
            print("General error: \(error)")
        }
            
        isLoadingObservations = false
    }
    
    func reset() {
        isCreatingObservation = false
        isLoadingObservations = false
        observationMessage = nil
        createdObservation = nil
        userObservations = []
        myObservations = []
    }
}
