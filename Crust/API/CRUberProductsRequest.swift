struct CRUberProductsRequest : CRRequest {
    
    var latitude: Double
    var longitude: Double
    
    init(withLatitude latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
    
    var requestUrl: String {
        return "products"
    }
    
    var queryParameters: [ String : AnyObject ] {
        return [
            "latitude" : latitude,
            "longitude" : longitude
        ]
    }
    
    var HTTPMethod: CRHTTPMethod {
        return CRHTTPMethod.GET
    }
}

struct CRUberPriceEstimatesRequest : CRRequest {
    
    var startLatitude: Double
    var startLongitude: Double
    var endLatitude: Double
    var endLongitude: Double
    
    init(withStartLatitude
        startLatitude: Double,
        startLongitude: Double,
        endLatitude: Double,
        endLongitude: Double) {
            
            self.startLatitude = startLatitude
            self.startLongitude = startLongitude
            self.endLatitude = endLatitude
            self.endLongitude = endLongitude
    }
    
    var requestUrl: String {
        return "estimates/price"
    }
    
    var queryParameters: [ String : AnyObject ] {
        return [
            "start_latitude" : startLatitude,
            "start_longitude" : startLongitude,
            "end_latitude" : endLatitude,
            "end_longitude" : endLongitude
        ]
    }
    
    var HTTPMethod: CRHTTPMethod {
        return CRHTTPMethod.GET
    }
}

struct CRUberTimeEstimatesRequest : CRRequest {
    
    var startLatitude: Double
    var startLongitude: Double
    
    init(withStartLatitude
        startLatitude: Double,
        startLongitude: Double) {
            
            self.startLatitude = startLatitude
            self.startLongitude = startLongitude
    }
    
    var requestUrl: String {
        return "estimates/time"
    }
    
    var queryParameters: [ String : AnyObject ] {
        return [
            "start_latitude" : startLatitude,
            "start_longitude" : startLongitude
        ]
    }
    
    var HTTPMethod: CRHTTPMethod {
        return CRHTTPMethod.GET
    }
}

struct CRUberPromotionsRequest : CRRequest {
    
    var startLatitude: Double
    var startLongitude: Double
    var endLatitude: Double
    var endLongitude: Double
    
    init(withStartLatitude
        startLatitude: Double,
        startLongitude: Double,
        endLatitude: Double,
        endLongitude: Double) {
            
            self.startLatitude = startLatitude
            self.startLongitude = startLongitude
            self.endLatitude = endLatitude
            self.endLongitude = endLongitude
    }
    
    var requestUrl: String {
        return "promotions"
    }
    
    var queryParameters: [ String : AnyObject ] {
        return [
            "start_latitude" : startLatitude,
            "start_longitude" : startLongitude,
            "end_latitude" : endLatitude,
            "end_longitude" : endLongitude
        ]
    }
    
    var HTTPMethod: CRHTTPMethod {
        return CRHTTPMethod.GET
    }
}
