struct Api {
    static let baseUrl = "https://8d3d-217-73-170-83.ngrok-free.app/"
    
    static var birdsEndpoint: String {
            return baseUrl + "birds"
    }
    
    static var birdLocationsEndpoint: String {
        return baseUrl + "location"
    }
}
struct Localhost {
    static let baseUrl = "https://8d3d-217-73-170-83.ngrok-free.app/"
    
    static var identifyBird: String {
            return baseUrl + "upload-sound"
    }

}
