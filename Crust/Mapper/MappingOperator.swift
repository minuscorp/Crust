import SwiftyJSON
import Runes

/**
* This file defines a new operator which is used to create a mapping between an object and a JSON key value.
* There is an overloaded operator definition for each type of object that is supported in ObjectMapper.
* This provides a way to add custom logic to handle specific types of objects
*/

infix operator >*< { associativity right }

public func >*< <T, U>(left: T, right: U) -> (T, U) {
    return (left, right)
}

public func >*< <T: CRMappingKey, U>(left: T, right: U) -> (CRMappingKey, U) {
    return (left, right)
}

infix operator <- { associativity right }

// MARK:- Objects with Basic types

/// Object of Basic type
public func <- <T: CRFieldType, C: CRMappingContext>(inout field: T, map:(key: CRMappingKey, context: C)) -> C {
    
    if case .Error(_)? = map.context.result {
        return map.context
    }
    
    switch map.context.dir {
    case .ToJSON:
        let json = map.context.json
        let result = mapToJson(json, fromField: field, viaKey: map.key)
        
        switch result {
        case .Value(let json):
            map.context.json = json
            map.context.result = Result.Value(json)
        case .Error(let error):
            map.context.result = Result.Error(error)
        }
    case .FromJSON:
        let baseJSON = map.context.json[map.key]
        map.context.result = mapFromJson(baseJSON, toField: &field)
    }
    
    return map.context
}

func mapToJson<T: CRFieldType>(var json: JSON, fromField field: T, viaKey key: CRMappingKey) -> Result<JSON> {
    
    print(key)
    json[key] = [ " fuck", " you" ]
    print(json)
    
    let result = field.asJSON()
    switch result {
    case .Value(let val):
        json[key] = val
    case .Error(_):
        return result
    }
    print(field)
    
    switch field {
    case is Bool:
        json[key] = JSON(field as! Bool)
    case is Int:
        json[key] = JSON(field as! Int)
    case is NSNumber:
        json[key] = JSON(field as! NSNumber)
    case is String:
        json[key] = JSON(field as! String)
    case is Float:
        json[key] = JSON(field as! Float)
    case is Double:
        json[key] = JSON(field as! Double)
    case is Array<Any>:
        let result = field.asJSON()
        switch result {
        case .Value(let val):
            json[key] = val
        case .Error(_):
            return result
        }
        print(field)
        break
    case is Dictionary<String, CRFieldType>:
        // TODO: Iterate through each element and wrap as JSON and add to our json.
//        json[key] = JSON(field as! Dictionary)
        print(field)
        break
    default:
        print("fuck")
        print(field)
        break
    }
    
    if let error = json.error {
        // TODO: Wrap this error in our own error.
        return Result.Error(error)
    }
    
    return Result.Value(json)
}

/// Map to JSON with field as optional type.
func mapToJson<T: CRFieldType>(var json: JSON, fromField field: T?, viaKey key: CRMappingKey) -> Result<JSON> {
    
    if let field = field {
        return mapToJson(json, fromField: field, viaKey: key)
    } else {
        json[key] = JSON(NSNull)
        return Result.Value(json)
    }
}

// TODO: Have a map for optional fields. .Null will map to `nil`.
func mapFromJson<T: CRFieldType>(json: JSON, inout toField field: T) -> Result<Any>? {
    
    // TODO: Clarify our errors.
    let error: NSError = NSError(domain: "CRMappingDomain", code: -1, userInfo: nil)
    
    if case .Unknown = json.type {
        return Result.Error(error)
    }
    
    switch field {
    case is Bool:
        if let rawBool = json.bool {
            field = rawBool as! T
        } else {
            return Result.Error(error)
        }
    case is Int:
        if let rawInt = json.number {
            field = rawInt as! T
        } else {
            return Result.Error(error)
        }
    case is NSNumber:
        if let rawNumber = json.number {
            field = rawNumber as! T
        } else {
            return Result.Error(error)
        }
    case is String:
        if let rawString = json.string {
            field = rawString as! T
        } else {
            return Result.Error(error)
        }
    case is Float:
        if let rawFloat = json.float {
            field = rawFloat as! T
        } else {
            return Result.Error(error)
        }
    case is Double:
        if let rawDouble = json.double {
            field = rawDouble as! T
        } else {
            return Result.Error(error)
        }
    case is Array<CRFieldType>:
        if let rawArray = json.array {
            field = rawArray as! T
        } else {
            return Result.Error(error)
        }
    case is Dictionary<String, CRFieldType>:
        if let rawDictionary = json.dictionary {
            field = rawDictionary as! T
        } else {
            return Result.Error(error)
        }
    default:
        return Result.Error(error)
    }
    
    return nil
}
