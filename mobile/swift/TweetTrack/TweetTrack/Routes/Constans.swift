struct Api {
    static let baseUrl = "https://7628-82-79-161-115.ngrok-free.app/"
    
    static var birdsEndpoint: String {
            return baseUrl + "birds"
    }
    
    static var birdLocationsEndpoint: String {
        return baseUrl + "location"
    }
    
    static var identifyBird: String {
            return baseUrl + "upload-sound"
    }
    
    static var register: String {
            return baseUrl + "register"
    }
    
    static var login: String {
            return baseUrl + "login"
    }
}
