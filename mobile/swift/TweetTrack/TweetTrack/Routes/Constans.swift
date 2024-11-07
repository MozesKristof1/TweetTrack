struct Api {
    static let baseUrl = "http://127.0.0.1:8000/"
    
    static var birdsEndpoint: String {
            return baseUrl + "birds"
    }
    
    static var birdLocationsEndpoint: String {
        return baseUrl + "location"
    }
}
