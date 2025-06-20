enum Api {
    static let baseUrl = "https://63cd-82-79-161-253.ngrok-free.app/"
    
    static var birdsEndpoint: String {
        return baseUrl + "birds?limit=100"
    }
    
    static func birdUserImages(_ ebirdId: String) -> String {
        return baseUrl + "images/" + ebirdId
    }
    
    static func userObservationsImages(_ observationId: String) -> String {
        return baseUrl + "observations/" + observationId + "/images"
    }

    static var observations: String {
        return baseUrl + "observations"
    }

    static var birdLocationsEndpoint: String {
        return baseUrl + "location"
    }
    
    static var identifyBird: String {
        return baseUrl + "classify"
    }
    
    static var register: String {
        return baseUrl + "register"
    }
    
    static var login: String {
        return baseUrl + "login"
    }
    
    static var myObservations: String {
        return baseUrl + "myobservations"
    }
    
}
