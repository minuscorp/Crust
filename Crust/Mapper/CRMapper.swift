import SwiftyJSON
import Runes

public enum Result<T> {
    case Value(T)
    case Error(NSError)
}

public enum MappingDirection {
    case FromJSON
    case ToJSON
}

public protocol CRMappingKey {
    var keyPath: String { get }
}

extension String : CRMappingKey {
    public var keyPath: String {
        return self
    }
}

public enum CRMapping : CRMappingKey {
    case ForeignKey(CRMappingKey)
    case Transform(CRMappingKey, String) // TODO: Second element should be Transform type to define later
    
    public var keyPath: String {
        switch self {
            
        case .ForeignKey(let keyPath):
            return keyPath.keyPath
            
        case .Transform(let keyPath, _):
            return keyPath.keyPath
        }
    }
}

public class CRMappingContext {
    public var JSON: SwiftyJSON.JSON
    public var dir: MappingDirection
    public var result: Result<Mappable>
    
    init(withObjectToJSON object: Mappable) {
        self.dir = MappingDirection.ToJSON
        self.result = Result.Value(object)
        self.JSON = SwiftyJSON.JSON([:])
    }
    
    init(withJSONToObject json: SwiftyJSON.JSON) {
        self.dir = MappingDirection.FromJSON
        self.result = setupResultToObject()
    }
    
    func setupResultToObject() -> Result<Mappable> {
        
    }
    
    /// Sets the current mapper value and key.
    /// The Key paramater can be a period separated string (ex. "distance.value") to access sub objects.
    public subscript(key: String) -> Map {
        
        let keyPath = key.componentsSeparatedByString(".").map { $0 as JSONSubscriptType }
        return valueForKeyPathComponents(keyPath, dictionary: SwiftyJSON.JSON)
    }
}

public protocol Mappable {
    static func newInstance() -> Mappable
    mutating func mapping(context: CRMappingContext)
    func foreignKeys() -> Array<CRMappingKey>
}

struct User : Mappable {
    var derp: String
    var blah: JSONSubscriptType
    
    static func newInstance() -> Mappable {
        return User(derp: "", blah: "")
    }
    
    func foreignKeys() -> Array<CRMappingKey> {
        return [ "Blah" ]
    }
    
    mutating func mapping(context: CRMappingContext) {
        
        blah <- CRMapping.Transform("Blah", "Blah") >*<
        derp <- "Derp" >*<
        context
    }
}

/// A class used for holding mapping data
public final class Map : CRMappingKey {
    public let mappingType: MappingType
    
    var JSON: SwiftyJSON.JSON
    var currentValue: AnyObject?
    var currentKey: String?
    
    var keyPath: String
    
    /// Counter for failing cases of deserializing values to `let` properties.
    // TODO: Doesn't look like this is used.
    private var failedCount: Int = 0
    
    private init(mappingType: MappingType, JSON: SwiftyJSON.JSON) {
        self.mappingType = mappingType
        self.JSON = JSON
    }
    
    /// Sets the current mapper value and key.
    /// The Key paramater can be a period separated string (ex. "distance.value") to access sub objects.
    public subscript(key: String) -> Map {
        
        currentKey = key
        let keyPath = key.componentsSeparatedByString(".").map { $0 as JSONSubscriptType }
        currentValue = valueForKeyPathComponents(keyPath, dictionary: JSON)
        
        return self
    }
    
    // MARK: Immutable Mapping
    
    public func value<T>() -> T? {
        return currentValue as? T
    }
    
    /// Returns whether the receiver is success or failure.
    public var isValid: Bool {
        return failedCount == 0
    }
}

/// Fetch value from JSON dictionary, loop through them until we reach the desired object.
private func valueForKeyPathComponents(components: [ JSONSubscriptType ], dictionary: JSON) -> AnyObject {

    let json = dictionary[Array(components)]
    return json.rawValue
}

protocol MapperType {
    func mapFromJSON(json: JSON, toObject object: Mappable) -> Mappable
}

public struct CRMapper : MapperType {
    
    func mapFromJSON(json: JSON, toObject object: Mappable) -> Mappable {
        let map = Map(mappingType: .FromJSON, JSONDictionary: JSONDictionary)
        object.mapping(map)
        return object
    }
}



/// The Mapper class provides methods for converting Model objects to JSON and methods for converting JSON to Model objects
public struct Mapper<N: Mappable> {

    // MARK: Mapping functions that map to an existing object toObject
    
    /// Map a JSON string onto an existing object
    public func map(JSONString: String, toObject object: N) -> N {
        
        if let JSON = parseJSONDictionary(JSONString) {
            return map(JSON, toObject: object)
        }
        return object
    }
    
    /// Maps a JSON object to an existing Mappable object if it is a JSON dictionary, or returns the passed object as is
    public func map(JSON: AnyObject?, toObject object: N) -> N {
        if let JSON = JSON as? [String : AnyObject] {
            return map(JSON, toObject: object)
        }
        
        return object
    }
    
    /// Maps a JSON dictionary to an existing object that conforms to Mappable.
    /// Usefull for those pesky objects that have crappy designated initializers like NSManagedObject
    public func map(JSONDictionary: [String : AnyObject], var toObject object: N) -> N {
        let map = Map(mappingType: .FromJSON, JSONDictionary: JSONDictionary)
        object.mapping(map)
        return object
    }
    
    //MARK: Mapping functions that create an object
    
    /// Map a JSON string to an object that conforms to Mappable
    public func map(JSONString: String) -> N? {
        if let JSON = parseJSONDictionary(JSONString) {
            return map(JSON)
        }
        return nil
    }
    
    /// Map a JSON NSString to an object that conforms to Mappable
    public func map(JSONString: NSString) -> N? {
        return map(JSONString as String)
    }
    
    /// Maps a JSON object to a Mappable object if it is a JSON dictionary or NSString, or returns nil.
    public func map(JSON: AnyObject?) -> N? {
        if let JSON = JSON as? [String : AnyObject] {
            return map(JSON)
        }
        
        return nil
    }
    
    /// Maps a JSON dictionary to an object that conforms to Mappable
    public func map(JSONDictionary: [String : AnyObject]) -> N? {
        if var object = N.newInstance() as? N {
            let map = Map(mappingType: .FromJSON, JSONDictionary: JSONDictionary)
            object.mapping(map)
            return object
        }
        return nil
    }
    
    //MARK: Mapping functions for Arrays and Dictionaries
    
    /// Maps a JSON array to an object that conforms to Mappable
    public func mapArray(JSONString: String) -> [N] {
        let parsedJSON: AnyObject? = parseJSONString(JSONString)
        
        if let objectArray = mapArray(parsedJSON) {
            return objectArray
        }
        
        // failed to parse JSON into array form
        // try to parse it into a dictionary and then wrap it in an array
        if let object = map(parsedJSON) {
            return [object]
        }
        
        return []
    }
    
    /// Maps a JSON object to an array of Mappable objects if it is an array of JSON dictionary, or returns nil.
    public func mapArray(JSON: AnyObject?) -> [N]? {
        if let JSONArray = JSON as? [[String : AnyObject]] {
            return mapArray(JSONArray)
        }
        
        return nil
    }
    
    /// Maps an array of JSON dictionary to an array of Mappable objects
    public func mapArray(JSONArray: [[String : AnyObject]]) -> [N] {
        // map every element in JSON array to type N
        return JSONArray.flatMap(map)
    }
    
    /// Maps a JSON object to a dictionary of Mappable objects if it is a JSON dictionary of dictionaries, or returns nil.
    public func mapDictionary(JSON: AnyObject?) -> [String : N]? {
        if let JSONDictionary = JSON as? [String : [String : AnyObject]] {
            return mapDictionary(JSONDictionary)
        }
        
        return nil
    }
    
    /// Maps a JSON dictionary of dictionaries to a dictionary of Mappble objects
    public func mapDictionary(JSONDictionary: [String : [String : AnyObject]]) -> [String : N] {
        // map every value in dictionary to type N
        return JSONDictionary.filterMap(map)
    }
    
    /// Maps a JSON object to a dictionary of arrays of Mappable objects
    public func mapDictionaryOfArrays(JSON: AnyObject?) -> [String : [N]]? {
        if let JSONDictionary = JSON as? [String : [[String : AnyObject]]] {
            return mapDictionaryOfArrays(JSONDictionary)
        }
        
        return nil
    }
    
    ///Maps a JSON dictionary of arrays to a dictionary of arrays of Mappable objects
    public func mapDictionaryOfArrays(JSONDictionary: [String : [[String : AnyObject]]]) -> [String : [N]] {
        // map every value in dictionary to type N
        return JSONDictionary.filterMap({ mapArray($0) })
    }
    
    // MARK: Functions that create JSON from objects
    
    ///Maps an object that conforms to Mappable to a JSON dictionary <String : AnyObject>
    public func toJSON(var object: N) -> [String : AnyObject] {
        let map = Map(mappingType: .ToJSON, JSONDictionary: [:])
        object.mapping(map)
        return map.JSON
    }
    
    ///Maps an array of Objects to an array of JSON dictionaries [[String : AnyObject]]
    public func toJSONArray(array: [N]) -> [[String : AnyObject]] {
        return array.map {
            // convert every element in array to JSON dictionary equivalent
            self.toJSON($0)
        }
    }
    
    ///Maps a dictionary of Objects that conform to Mappable to a JSON dictionary of dictionaries.
    public func toJSONDictionary(dictionary: [String : N]) -> [String : [String : AnyObject]] {
        return dictionary.map { k, v in
            // convert every value in dictionary to its JSON dictionary equivalent
            return (k, self.toJSON(v))
        }
    }
    
    ///Maps a dictionary of Objects that conform to Mappable to a JSON dictionary of dictionaries.
    public func toJSONDictionaryOfArrays(dictionary: [String : [N]]) -> [String : [[String : AnyObject]]] {
        return dictionary.map { k, v in
            // convert every value (array) in dictionary to its JSON dictionary equivalent
            return (k, self.toJSONArray(v))
        }
    }
    
    /// Maps an Object to a JSON string
    public func toJSONString(object: N, prettyPrint: Bool) -> String? {
        let JSONDict = toJSON(object)
        
        if NSJSONSerialization.isValidJSONObject(JSONDict) {
            let options: NSJSONWritingOptions = prettyPrint ? .PrettyPrinted : []
            let JSONData: NSData?
            do {
                JSONData = try NSJSONSerialization.dataWithJSONObject(JSONDict, options: options)
            } catch let error {
                print(error)
                JSONData = nil
            }
            
            if let JSON = JSONData {
                return NSString(data: JSON, encoding: NSUTF8StringEncoding) as? String
            }
        }
        
        return nil
    }
    
    // MARK: Private utility functions for converting strings to JSON objects
    
    /// Convert a JSON String into a Dictionary<String, AnyObject> using NSJSONSerialization
    private func parseJSONDictionary(JSON: String) -> [String : AnyObject]? {
        
        let parsedJSON: AnyObject? = parseJSONString(JSON)
        return parseJSONDictionary(parsedJSON)
    }
    
    /// Convert a JSON Object into a Dictionary<String, AnyObject> using NSJSONSerialization
    private func parseJSONDictionary(JSON: AnyObject?) -> [String : AnyObject]? {
        if let JSONDict = JSON as? [String : AnyObject] {
            return JSONDict
        }
        
        return nil
    }
    
    /// Convert a JSON String into an Object using NSJSONSerialization
    private func parseJSONString(JSON: String) -> AnyObject? {
        let data = JSON.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
        if let data = data {
            let parsedJSON: AnyObject?
            do {
                parsedJSON = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments)
            } catch let error {
                print(error)
                parsedJSON = nil
            }
            return parsedJSON
        }
        
        return nil
    }
}

extension Mapper where N: Hashable{
    
    /// Maps a JSON array to an object that conforms to Mappable
    public func mapSet(JSONString: String) -> Set<N> {
        let parsedJSON: AnyObject? = parseJSONString(JSONString)
        
        if let objectArray = mapArray(parsedJSON){
            return Set(objectArray)
        }
        
        // failed to parse JSON into array form
        // try to parse it into a dictionary and then wrap it in an array
        if let object = map(parsedJSON) {
            return Set([object])
        }
        
        return Set()
    }
    
    /// Maps a JSON object to an Set of Mappable objects if it is an array of JSON dictionary, or returns nil.
    public func mapSet(JSON: AnyObject?) -> Set<N>? {
        if let JSONArray = JSON as? [[String : AnyObject]] {
            return mapSet(JSONArray)
        }
        
        return nil
    }
    
    /// Maps an Set of JSON dictionary to an array of Mappable objects
    public func mapSet(JSONArray: [[String : AnyObject]]) -> Set<N> {
        // map every element in JSON array to type N
        return Set(JSONArray.flatMap(map))
    }
    
    ///Maps a Set of Objects to a Set of JSON dictionaries [[String : AnyObject]]
    public func toJSONSet(set: Set<N>) -> [[String : AnyObject]] {
        return set.map {
            // convert every element in set to JSON dictionary equivalent
            self.toJSON($0)
        }
    }
    
}

extension Dictionary {
    internal func map<K: Hashable, V>(@noescape f: Element -> (K, V)) -> [K : V] {
        var mapped = [K : V]()
        
        for element in self {
            let newElement = f(element)
            mapped[newElement.0] = newElement.1
        }
        
        return mapped
    }
    
    internal func map<K: Hashable, V>(@noescape f: Element -> (K, [V])) -> [K : [V]] {
        var mapped = [K : [V]]()
        
        for element in self {
            let newElement = f(element)
            mapped[newElement.0] = newElement.1
        }
        
        return mapped
    }
    
    
    internal func filterMap<U>(@noescape f: Value -> U?) -> [Key : U] {
        var mapped = [Key : U]()
        
        for (key, value) in self {
            if let newValue = f(value){
                mapped[key] = newValue
            }
        }
        
        return mapped
    }
}
