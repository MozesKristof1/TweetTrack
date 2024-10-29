struct Api {
    static let baseUrl = "http://localhost:5252/api/"
    
    static var birdsEndpoint: String {
            return baseUrl + "birds"
    }
}
