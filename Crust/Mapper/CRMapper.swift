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

public protocol CRFieldType {
    func asJSON() -> Result<JSON>
}

public protocol CRFieldCollection: CRFieldType, CollectionType {
}

extension CRFieldCollection {
    
}

extension Bool : CRFieldType {
    public func asJSON() -> Result<JSON> {
        return Result.Value(JSON(self))
    }
}

extension NSNumber : CRFieldType {
    public func asJSON() -> Result<JSON> {
        return Result.Value(JSON(self))
    }
}

extension NSNull : CRFieldType {
    public func asJSON() -> Result<JSON> {
        return Result.Value(JSON(self))
    }
}

extension Dictionary : CRFieldType {
    public func asJSON() -> Result<JSON> {
        return dictionaryAsJSON(self)
    }
    
    func dictionaryAsJSON<T: CRFieldType>(dictionary: T) -> Result<JSON> {
        switch dictionary {
        case is Dictionary<String, CRFieldType>:
            return Result.Value(JSON(NSNull)) // TODO:
        default:
            return Result.Error(NSError(domain: "", code: 0, userInfo: nil))
        }
    }
}

extension Set : CRFieldType {
    public func asJSON() -> Result<JSON> {
        return Result.Error(NSError(domain: "", code: 0, userInfo: nil))
    }
}

extension Array : CRFieldType {
    public func asJSON() -> Result<JSON> {
        
        switch Element.self {
        case is CRFieldType.Type:
            
            var resultArray = Array<JSON>()
            
            for val in self {
                let val = val as! CRFieldType
                let result = val.asJSON()
                
                switch result {
                case .Value(let val):
                    print(val)
                    resultArray.append(val)
                    print(resultArray)
                case .Error(_):
                    return result
                }
            }
            print(resultArray)
            return Result.Value(JSON(resultArray))
            
        default:
            return Result.Error(NSError(domain: "", code: 0, userInfo: nil))
        }
    }
    
    // Type constraints on generics aren't very elaborate in swift yet.
    // Can't express Array<CRFieldType>: CRFieldType so need to handle the general case.
    // Covers our default case of any array.
    func jsonConversion<T>(array: T) -> Result<JSON> {
        
        return Result.Error(NSError(domain: "", code: 0, userInfo: nil))
        
//        switch array {
//        case is Array<NSNumber>:
//            return jsonConversion(array as! Array<CRFieldType>)
//        case is Array<Bool>:
//            return jsonConversion(array as! Array<CRFieldType>)
//        case is Array<Int>:
//            return jsonConversion(array as! Array<CRFieldType>)
//        case is Array<Double>:
//            return jsonConversion(array as! Array<CRFieldType>)
//        case is Array<Float>:
//            return jsonConversion(array as! Array<CRFieldType>)
//        case is Array<String>:
//            return jsonConversion(array as! Array<CRFieldType>)
//        case is Array<CRFieldType>:
//            return jsonConversion(array as! Array<CRFieldType>)
//        default:
//            return Result.Error(NSError(domain: "", code: 0, userInfo: nil))
//        }
    }
    
    func jsonConversion(array: Array<CRFieldType>) -> Result<JSON> {
        var resultArray = Array<JSON>()
        for val in array {
            let result = val.asJSON()
            switch result {
            case .Value(let val):
                resultArray.append(val)
            case .Error(_):
                return result
            }
        }
        return Result.Value(JSON(resultArray))
    }
}

extension Float : CRFieldType {
    public func asJSON() -> Result<JSON> {
        return Result.Value(JSON(self))
    }
}

extension Double : CRFieldType {
    public func asJSON() -> Result<JSON> {
        return Result.Value(JSON(self))
    }
}

extension Int : CRMappingKey, CRFieldType {
    public var keyPath: String {
        return String(self)
    }
    public func asJSON() -> Result<JSON> {
        return Result.Value(JSON(self))
    }
}

extension String : CRMappingKey, CRFieldType {
    public var keyPath: String {
        return self
    }
    public func asJSON() -> Result<JSON> {
        return Result.Value(JSON(self))
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

extension JSON {
    subscript(key: CRMappingKey) -> JSON {
        get {
            let components = key.keyPath.componentsSeparatedByString(".").map { $0 as JSONSubscriptType }
            let json = self[Array(components)]
            return json
        }
        set {
            let components = key.keyPath.componentsSeparatedByString(".").map { $0 as JSONSubscriptType }
            self[Array(components)] = newValue
        }
    }
}

public class CRMappingContext {
    public var json: SwiftyJSON.JSON
    public var object: Mappable
    public var dir: MappingDirection
    public var result: Result<Any>?
    
    init(withObject object:Mappable, json: JSON, direction: MappingDirection) {
        self.dir = direction
        self.object = object
        self.json = json
    }
}

/// Global methods caller uses to perform mappings.
public struct CRMapper<T: Mappable> {
    
    func mapFromJSONToObject(json: JSON) -> Result<Any> {
        let object = getInstance()
        return mapFromJSON(json, toObject: object)
    }
    
    func mapFromJSON(json: JSON, var toObject object: T) -> Result<Any> {
        let context = CRMappingContext(withObject: object, json: json, direction: MappingDirection.FromJSON)
        object.mapping(context)
        return context.result!
    }
    
    func mapFromObjectToJSON(object: T) -> Result<Any> {
        let context = CRMappingContext(withObject: object, json: JSON([:]), direction: MappingDirection.ToJSON)
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

public protocol Mappable : CRFieldType {
    static func newInstance() -> Mappable
    static func foreignKeys() -> Array<CRMappingKey>
    mutating func mapping(context: CRMappingContext)
}

extension Mappable {
    public func asJSON() -> Result<JSON> {
        return Result.Value(JSON(NSNull)) // TODO:
    }
}
