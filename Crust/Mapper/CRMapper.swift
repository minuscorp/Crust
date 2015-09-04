import Runes
import Swiftz

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

//public protocol CRFieldType : JSON {
//    func asJSON() -> Result<JSONValue>
//}

extension Dictionary where Key : String, Value : JSON, Value.J == Value {
    
    public static func toJSON(x: Dictionary<Key, Value>) -> JSONValue {
        return JDictionary<Value, Value>.toJSON(x)
    }
    
    public static func fromJSON(x: JSONValue) -> Dictionary<Key, Value>? {
        return JDictionary<Value, Value>.fromJSON(x)
    }
}

extension Set where Element : JSON, Element.J == Element {
    
    public static func toJSON(x: Set<Element>) -> JSONValue {
        let array = Array(x)
        return JArray<Element, Element>.toJSON(array)
    }
    
    public static func fromJSON(x: JSONValue) -> Set<Element>? {
        if let array = JArray<Element, Element>.fromJSON(x) {
            return Set(array)
        } else {
            return nil
        }
    }
}

extension Array : JSON {
    
    public static func toJSON(x: Array) -> JSONValue {
        return self.toJSON(self)
    }
    
    public static func fromJSON(x: JSONValue) -> Array? {
        <#code#>
    }
    
    func toJSON<T: JSON>(x: Array<T>) -> JSONValue {
        
    }
}

extension Array where Element : JSON, Element.J == Element {
    
    public func toJSON(x: Array<Element>) -> JSONValue {
        return JArray<Element, Element>.toJSON(x)
    }
    
    public func fromJSON(x: JSONValue) -> Array? {
        return JArray<Element, Element>.fromJSON(x)
    }
}

//extension Array : CRFieldType {
//    public func asJSON() -> Result<JSONValue> {
//        
//        switch Element.self {
//        case is CRFieldType.Type:
//            
//            var resultArray = Array<JSONValue>()
//            
//            for val in self {
//                let val = val as! CRFieldType
//                let result = val.asJSON()
//                
//                switch result {
//                case .Value(let val):
//                    print(val)
//                    resultArray.append(val)
//                    print(resultArray)
//                case .Error(_):
//                    return result
//                }
//            }
//            print(resultArray)
//            return Result.Value(JSONValue.JSONArray(resultArray))
//            
//        default:
//            return Result.Error(NSError(domain: "", code: 0, userInfo: nil))
//        }
//    }
//}

extension Int : CRMappingKey {
    public var keyPath: String {
        return String(self)
    }
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

//extension JSONValue {
//    subscript(key: CRMappingKey) -> JSONValue? {
//        get {
//            let components = key.keyPath.componentsSeparatedByString(".")
//            let value: JSONValue? = (self <? JSONKeypath.init(components))
//            return self <? JSONKeypath.init(components)
////            let components = key.keyPath.componentsSeparatedByString(".").map { $0 as JSONSubscriptType }
////            let json = self[Array(components)]
////            return json
//        }
//        set {
//            let components = key.keyPath.componentsSeparatedByString(".").map { $0 as JSONSubscriptType }
//            self[Array(components)] = newValue
//        }
//    }
//}

public class CRMappingContext {
    public var json: JSONValue
    public var object: Mappable
    public var dir: MappingDirection
    public var result: Result<Any>?
    
    init(withObject object:Mappable, json: JSONValue, direction: MappingDirection) {
        self.dir = direction
        self.object = object
        self.json = json
    }
}

/// Global methods caller uses to perform mappings.
public struct CRMapper<T: Mappable> {
    
    func mapFromJSONToObject(json: JSONValue) -> Result<Any> {
        let object = getInstance()
        return mapFromJSON(json, toObject: object)
    }
    
    func mapFromJSON(json: JSONValue, var toObject object: T) -> Result<Any> {
        let context = CRMappingContext(withObject: object, json: json, direction: MappingDirection.FromJSON)
        object.mapping(context)
        return context.result!
    }
    
    func mapFromObjectToJSON(object: T) -> Result<Any> {
        let context = CRMappingContext(withObject: object, json: JSONValue.JSONObject([:]), direction: MappingDirection.ToJSON)
        return performMappingWithObject(object, context: context)
    }
    
    internal func performMappingWithObject(var object: T, context: CRMappingContext) -> Result<Any> {
        object.mapping(context)
        return context.result!
    }
    
    internal func getInstance() -> T {
        // TODO: Find by foreignKeys else...
        return T.newInstance() as! T
    }
}

public protocol Mappable  {
    static func newInstance() -> Mappable
    static func foreignKeys() -> Array<CRMappingKey>
    mutating func mapping(context: CRMappingContext)
}
