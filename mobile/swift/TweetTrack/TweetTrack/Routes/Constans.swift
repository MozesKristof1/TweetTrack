struct Api {
    static let baseUrl = "https://tweet-track-h4mmeu8mi-kristofs-projects-43e78ed6.vercel.app/"
    
    static var birdsEndpoint: String {
            return baseUrl + "birds"
    }
    
    static var birdLocationsEndpoint: String {
        return baseUrl + "location"
    }
}
