struct User : Mappable {
    var derp: String
    var blah: Int
    
    static func newInstance() -> Mappable {
        return User(derp: "", blah: 0)
    }
    
    static func foreignKeys() -> Array<CRMappingKey> {
        return [ "Blah" ]
    }
    
    mutating func mapping(context: CRMappingContext) {
        
        blah <- CRMapping.Transform("Blah", "Blah") >*<
        derp <- "Derp" >*<
        context
    }
}

protocol Adaptor {
    func fetchObjectForForeignKeys(keys: Array<CRMappingKey>) -> Mappable
    func deleteObject<T: Mappable>(obj: T)
}

protocol Mapping {
    var adaptor: Adaptor { get }
    
    func foreignKeys() -> Array<CRMappingKey>
    mutating func mapping<T: Mappable>(tomap: T, context: CRMappingContext)
}

// Have something along the lines of.
// func registerMapping(mapping: Mapping, forPath path: URLPath)